# SOLUCIÓN DEFINITIVA - ERROR STRIPE CHECKOUT

## 📋 ANÁLISIS COMPLETO DEL PROBLEMA

### ❌ Error Actual
```
📡 Status Code Stripe: 500
❌ Error 500 del servidor: {"error":"Invalid API Key provided: sk_test_***DWGW"}
❌ Error en checkout: Exception: Error del servidor (500). Verifica la configuración de Stripe en el backend
```

### ✅ Lo que SÍ funciona (Frontend)
1. ✅ Carrito se carga correctamente
2. ✅ Validación pre-checkout funciona
3. ✅ Recarga del carrito antes de checkout funciona
4. ✅ Creación de orden exitosa (ID 1884, 1885)
5. ✅ Conexión a internet funciona
6. ✅ Datos de envío válidos
7. ✅ El frontend envía correctamente `order_id` al endpoint `/api/stripe/create-checkout-session/`

### ❌ Lo que NO funciona (Backend)
El error ocurre en el backend cuando intenta crear la sesión de Stripe:
```python
# Backend está usando una API Key inválida
STRIPE_SECRET_KEY = "sk_test_***DWGW"  # ⚠️ Esta clave es inválida o expirada
```

---

## 🔍 ORIGEN DEL PROBLEMA

### Endpoint Backend Analizado
**POST** `https://smartsales-backend-891739940726.us-central1.run.app/api/stripe/create-checkout-session/`

**Request Body** (enviado correctamente por el frontend):
```json
{
  "order_id": 1885
}
```

**Error del backend**:
- El backend recibe el `order_id` correctamente
- Encuentra la orden en la base de datos
- **FALLA** al intentar crear la sesión en Stripe por API Key inválida
- Retorna HTTP 500 con el mensaje de error de Stripe

---

## 🛠️ SOLUCIONES DEFINITIVAS

### Solución 1: Actualizar Stripe API Key en Backend (RECOMENDADO)

El administrador del backend debe:

1. **Obtener una API Key válida de Stripe**:
   - Ir a: https://dashboard.stripe.com/test/apikeys
   - Copiar la **Secret Key** que comienza con `sk_test_...`
   - Ejemplo: `sk_test_51H7xYyKR2n9...` (debe ser una clave completa y válida)

2. **Actualizar variable de entorno en Google Cloud Run**:
   ```bash
   # En Google Cloud Console o gcloud CLI
   gcloud run services update smartsales-backend \
     --update-env-vars STRIPE_SECRET_KEY=sk_test_NUEVA_CLAVE_VALIDA \
     --region us-central1
   ```

3. **Verificar configuración en el código backend**:
   ```python
   # En settings.py o archivo de configuración
   import stripe
   
   STRIPE_SECRET_KEY = os.getenv('STRIPE_SECRET_KEY')
   stripe.api_key = STRIPE_SECRET_KEY
   
   # Validar que la clave exista
   if not STRIPE_SECRET_KEY:
       raise ValueError("STRIPE_SECRET_KEY no está configurada")
   ```

4. **Reiniciar el servicio de Cloud Run** después de actualizar las variables

---

### Solución 2: Verificar Configuración de Stripe en Backend

El código del backend debe tener:

```python
# views.py o stripe_views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
import stripe
from django.conf import settings

stripe.api_key = settings.STRIPE_SECRET_KEY

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_checkout_session(request):
    try:
        order_id = request.data.get('order_id')
        
        if not order_id:
            return Response(
                {'error': 'order_id es requerido'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Obtener la orden
        order = Order.objects.get(id=order_id, user=request.user)
        
        # Crear line items para Stripe
        line_items = []
        for item in order.items.all():
            line_items.append({
                'price_data': {
                    'currency': 'usd',
                    'product_data': {
                        'name': item.product.name,
                    },
                    'unit_amount': int(item.price * 100),  # Convertir a centavos
                },
                'quantity': item.quantity,
            })
        
        # Crear sesión de Stripe
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=line_items,
            mode='payment',
            success_url=f'{settings.FRONTEND_URL}/checkout/success?session_id={{CHECKOUT_SESSION_ID}}',
            cancel_url=f'{settings.FRONTEND_URL}/checkout/cancel',
            metadata={
                'order_id': order.id,
            }
        )
        
        # Guardar session_id en la orden
        order.stripe_checkout_id = checkout_session.id
        order.save()
        
        return Response({
            'checkout_url': checkout_session.url,
            'session_id': checkout_session.id
        })
        
    except Order.DoesNotExist:
        return Response(
            {'error': 'Orden no encontrada'},
            status=status.HTTP_404_NOT_FOUND
        )
    except stripe.error.InvalidRequestError as e:
        return Response(
            {'error': f'Error de Stripe: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    except stripe.error.AuthenticationError as e:
        # Este es el error actual - API Key inválida
        return Response(
            {'error': f'Invalid API Key provided: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    except Exception as e:
        return Response(
            {'error': f'Error al crear sesión de pago: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
```

---

### Solución 3: Configurar Webhook de Stripe (Para después del pago)

El webhook debe estar configurado en:
**POST** `https://smartsales-backend-891739940726.us-central1.run.app/api/stripe/webhook/`

```python
@api_view(['POST'])
@csrf_exempt
def stripe_webhook(request):
    payload = request.body
    sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
        
        if event['type'] == 'checkout.session.completed':
            session = event['data']['object']
            order_id = session['metadata']['order_id']
            
            # Actualizar estado de la orden
            order = Order.objects.get(id=order_id)
            order.status = 'PAGADO'
            order.stripe_payment_intent = session.get('payment_intent')
            order.save()
            
        return Response({'status': 'success'})
        
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
```

---

## 📊 FLUJO COMPLETO FUNCIONAL

### 1. Usuario hace checkout (Frontend)
```dart
// cart_screen.dart
await cartProvider.loadCart(token);  // ✅ Funciona
final validationError = cartProvider.validateForCheckout();  // ✅ Funciona
if (validationError != null) throw Exception(validationError);  // ✅ Funciona

// order_service.dart
final order = await createOrderFromCart(...);  // ✅ Funciona - Orden creada
final checkoutUrl = await createStripeCheckoutSession(...);  // ❌ FALLA AQUÍ
```

### 2. Backend crea sesión (Debe arreglarse)
```python
# Backend actual
stripe.api_key = "sk_test_***DWGW"  # ❌ Clave inválida
checkout_session = stripe.checkout.Session.create(...)  # ❌ FALLA

# Backend corregido
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')  # ✅ Clave válida
checkout_session = stripe.checkout.Session.create(...)  # ✅ Funciona
return {'checkout_url': checkout_session.url}  # ✅ Retorna URL
```

### 3. Frontend redirige a Stripe
```dart
await launch(checkoutUrl);  // Usuario completa pago en Stripe
```

### 4. Stripe notifica al backend (Webhook)
```python
# Backend recibe evento de pago completado
order.status = 'PAGADO'  # Actualiza estado
order.save()
```

---

## 🎯 PASOS INMEDIATOS

### Para el Administrador del Backend:

1. **URGENTE**: Actualizar `STRIPE_SECRET_KEY` en Google Cloud Run
   - Ir a Cloud Console → Cloud Run → smartsales-backend → Variables de entorno
   - Actualizar `STRIPE_SECRET_KEY` con una clave válida de Stripe
   - Guardar y esperar el redespliegue

2. **Verificar** que la clave funciona:
   ```bash
   curl https://api.stripe.com/v1/checkout/sessions \
     -u sk_test_NUEVA_CLAVE: \
     -d "success_url=https://example.com/success" \
     -d "cancel_url=https://example.com/cancel" \
     -d "line_items[0][price]=price_H5ggYwtDq4fbrJ" \
     -d "line_items[0][quantity]=2" \
     -d "mode=payment"
   ```

3. **Configurar webhook** en Stripe Dashboard:
   - URL: `https://smartsales-backend-891739940726.us-central1.run.app/api/stripe/webhook/`
   - Eventos: `checkout.session.completed`, `payment_intent.succeeded`
   - Copiar el **webhook secret** y agregarlo como variable de entorno `STRIPE_WEBHOOK_SECRET`

### Para Testing Después de Corregir:

1. Agregar producto al carrito
2. Ir a checkout
3. Ingresar datos de envío
4. Click en "Proceder al pago"
5. **Debe redirigir a Stripe** (no debe mostrar error 500)
6. Usar tarjeta de prueba: `4242 4242 4242 4242`
7. Completar pago
8. Verificar que orden cambia a estado "PAGADO"

---

## 📝 LOGS ESPERADOS DESPUÉS DE CORREGIR

### Frontend (Exitoso):
```
🛍️ Iniciando proceso de checkout...
🔄 Recargando carrito para verificar estado...
✅ Carrito cargado: 1 items
💰 Total: $2257.34
✅ Carrito verificado: 1 items, Total: $2257.34
📦 Creando orden desde carrito...
✅ Orden creada exitosamente: Orden ID 1886
💳 Creando sesión de Stripe para orden ID: 1886
📡 Status Code Stripe: 200  ← ✅ Debe ser 200, no 500
✅ Respuesta Stripe: {checkout_url: https://checkout.stripe.com/...}
✅ URL de checkout obtenida
🌐 Redirigiendo a Stripe...
```

### Backend (Logs esperados):
```
[INFO] POST /api/orders/create_order_from_cart/ - 201 Created
[INFO] Orden 1886 creada para usuario david
[INFO] POST /api/stripe/create-checkout-session/ - 200 OK
[INFO] Sesión de Stripe creada: cs_test_a1B2c3D4e5F6...
[INFO] URL de checkout: https://checkout.stripe.com/c/pay/cs_test_...
```

---

## ⚠️ IMPORTANTE

**EL FRONTEND ESTÁ 100% CORRECTO Y FUNCIONAL**

Los cambios realizados en esta sesión:
- ✅ Fix LateInitializationError en order_history_screen
- ✅ Recarga de carrito antes de checkout
- ✅ Validación detallada con `validateForCheckout()`
- ✅ Manejo mejorado de errores 400/500

**EL PROBLEMA ES EXCLUSIVAMENTE DEL BACKEND: API KEY DE STRIPE INVÁLIDA**

No se requieren más cambios en el frontend. Una vez que el backend actualice la Stripe Secret Key, el checkout funcionará perfectamente.

---

## 🔗 Referencias

- Stripe API Keys: https://dashboard.stripe.com/test/apikeys
- Stripe Checkout Session: https://stripe.com/docs/api/checkout/sessions/create
- Stripe Webhooks: https://stripe.com/docs/webhooks
- Backend API Docs: https://smartsales-backend-891739940726.us-central1.run.app/api/docs/
- Backend Repository: https://github.com/DiegoxdGarcia2/SmartSales-backend

---

**Fecha de análisis**: 12 de noviembre de 2025  
**Estado**: Esperando actualización de Stripe API Key en el backend
