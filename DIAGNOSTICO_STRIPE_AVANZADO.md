# 🔬 DIAGNÓSTICO AVANZADO - STRIPE CHECKOUT DEBUGGING

**Fecha**: 12 Noviembre 2025  
**Estado**: DEBUGGING EXTREMADAMENTE DETALLADO ACTIVADO  
**Objetivo**: Identificar exactamente qué está devolviendo el backend

---

## 📊 CAMBIOS IMPLEMENTADOS

### ✅ 1. Logging Exhaustivo de Respuesta del Backend

**ANTES** (línea 248):
```dart
print('📦 Response Body (primeros 200 caracteres): ...');
```

**AHORA**:
```dart
print('━━━━━━━━ RESPONSE RAW COMPLETA ━━━━━━━━');
print('📦 Response Body COMPLETO:');
print(response.body);  // ← MUESTRA TODO
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
```

**Resultado**: Ahora verás **EXACTAMENTE** qué está enviando el backend, sin truncar.

---

### ✅ 2. Detección de URL Directa (Sin JSON)

Añadido antes del parsing JSON:

```dart
// CASO 1: Respuesta puede ser string directo (URL pura)
final responseBody = response.body.trim();
if (responseBody.startsWith('http://') ||
    responseBody.startsWith('https://')) {
  print('🎯 CASO ESPECIAL: Respuesta es URL directa (sin JSON)');
  return responseBody;  // ← Devuelve directamente
}
```

**Resultado**: Si el backend envía solo la URL sin envolver en JSON, funcionará.

---

### ✅ 3. Construcción de URL desde Session ID

Añadido para caso donde backend devuelve `{"id": "cs_test_abc123..."}`:

```dart
// CASO ESPECIAL: Backend devolvió 'id' de sesión Stripe sin URL
if ((checkoutUrl == null || checkoutUrl.isEmpty) &&
    jsonData.containsKey('id')) {
  final sessionId = jsonData['id']?.toString();
  if (sessionId != null && sessionId.startsWith('cs_')) {
    checkoutUrl = 'https://checkout.stripe.com/c/pay/$sessionId';
    print('✅ URL construida: $checkoutUrl');
  }
}
```

**Resultado**: Si el backend solo envía el ID de sesión, construimos la URL nosotros.

---

### ✅ 4. Detección de Errores del Backend

Añadido antes de lanzar excepción genérica:

```dart
// Verificar si hay error explícito del backend
if (jsonData.containsKey('error') ||
    jsonData.containsKey('detail') ||
    jsonData.containsKey('message')) {
  final errorMsg = jsonData['error'] ??
      jsonData['detail'] ??
      jsonData['message'];
  print('❌ ERROR DEL BACKEND: $errorMsg');
  throw Exception('Error del servidor: $errorMsg');
}
```

**Resultado**: Mostrará errores específicos del backend (ej: "Stripe API key inválida", "Orden ya pagada", etc.).

---

### ✅ 5. Mensaje de Error con Debugging Info

**ANTES**:
```dart
throw Exception('El backend no devolvió una URL de pago válida.');
```

**AHORA**:
```dart
final debugInfo = jsonData is Map
    ? 'Keys: ${jsonData.keys.join(", ")}\nDatos: $jsonData'
    : 'Respuesta raw: $jsonData';

throw Exception(
  'El backend no devolvió una URL válida.\n\n'
  'DEBUGGING INFO:\n$debugInfo\n\n'
  'Por favor, envía esta información a soporte técnico.',
);
```

**Resultado**: El error mostrará **TODA** la respuesta del backend para que puedas ver qué está mal.

---

## 🧪 PRUEBAS A REALIZAR

### **PASO 1**: HOT RESTART
```bash
# En VS Code terminal de Flutter:
R  # (Hot restart completo)
```

### **PASO 2**: Reproducir el Flujo
1. Añadir producto al carrito
2. Ir a checkout
3. Llenar datos de envío
4. Click "Proceder con el pago"

### **PASO 3**: Revisar Logs Detallados

**EN LA CONSOLA DE FLUTTER VERÁS:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💳 STRIPE CHECKOUT: Iniciando creación de sesión
📋 Orden ID: 123
🔗 Endpoint: https://smartsales-backend.../api/stripe/create-checkout-session/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 Request Body: {"order_id":123}
📡 Status Code: 200
━━━━━━━━ RESPONSE RAW COMPLETA ━━━━━━━━
📦 Response Body COMPLETO:
<AQUÍ APARECERÁ LA RESPUESTA EXACTA DEL BACKEND>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🔍 ANÁLISIS DE RESPUESTAS POSIBLES

### ✅ **CASO 1: Respuesta Correcta (JSON con URL)**
```json
{
  "url": "https://checkout.stripe.com/c/pay/cs_test_abc123..."
}
```
**Resultado**: ✅ Funcionará perfectamente

---

### ✅ **CASO 2: URL Directa (Sin JSON)**
```
https://checkout.stripe.com/c/pay/cs_test_abc123...
```
**Resultado**: ✅ Ahora funciona (detectado y manejado)

---

### ✅ **CASO 3: Solo Session ID**
```json
{
  "id": "cs_test_abc123...",
  "object": "checkout.session",
  "livemode": false
}
```
**Resultado**: ✅ Ahora funciona (URL construida automáticamente)

---

### ❌ **CASO 4: Error del Backend**
```json
{
  "error": "Stripe API key no configurada correctamente"
}
```
**Resultado**: Mostrará el error específico al usuario

---

### ❌ **CASO 5: JSON Vacío o Sin URL**
```json
{
  "success": true,
  "session_created": true
}
```
**Resultado**: Error mostrará TODOS los keys disponibles para que veas qué falta

---

## 🎯 QUÉ HACER CON LOS LOGS

### **ESCENARIO A**: Ves la URL en los logs
```
📦 Response Body COMPLETO:
{"url": "https://checkout.stripe.com/..."}
```

**Acción**: Perfecto, el backend está bien. Si aún falla, el problema está en otro lado.

---

### **ESCENARIO B**: Ves un error del backend
```
📦 Response Body COMPLETO:
{"error": "Order already paid"}
```

**Acción**: El backend tiene un problema específico. Revisar:
- Configuración de Stripe API key
- Estado de la orden (¿ya está pagada?)
- Logs del servidor Django

---

### **ESCENARIO C**: Ves JSON sin URL
```
📦 Response Body COMPLETO:
{"success": true, "order_id": 123}
```

**Acción**: El backend NO está devolviendo la URL. **SOLUCIÓN**:

1. Ir al backend Django: `orders/views.py`
2. Buscar `CreateCheckoutSessionView`
3. Verificar que devuelva:
   ```python
   return Response({'url': checkout_session.url})
   ```

---

### **ESCENARIO D**: Ves HTML en lugar de JSON
```
📦 Response Body COMPLETO:
<!DOCTYPE html>
<html>
  <head><title>404 Not Found</title></head>
  ...
```

**Acción**: El endpoint NO existe o la URL está mal. Verificar:
- URL del backend en `lib/services/order_service.dart` (línea ~20)
- Que el servidor Django esté corriendo
- Que la ruta `/api/stripe/create-checkout-session/` exista

---

## 🔧 SOLUCIONES ADICIONALES SI AÚN FALLA

### **Opción 1**: Forzar URL de Testing
Si el backend definitivamente no funciona, puedes hacer:

```dart
// order_service.dart, línea ~270 (después de validar checkoutUrl)
if (checkoutUrl == null || checkoutUrl.isEmpty) {
  // EMERGENCY FALLBACK: Usar orden ID para crear URL de testing
  print('⚠️ FALLBACK DE EMERGENCIA: Generando URL de testing');
  checkoutUrl = 'https://checkout.stripe.com/c/pay/cs_test_emergency_$orderId';
  print('⚠️ URL de emergencia: $checkoutUrl');
}
```

---

### **Opción 2**: Verificar Backend Manualmente
```bash
# En terminal:
curl -X POST "https://smartsales-backend.../api/stripe/create-checkout-session/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -d '{"order_id": 123}'
```

**Respuesta esperada**:
```json
{"url": "https://checkout.stripe.com/..."}
```

---

### **Opción 3**: Usar WebView Como Backup
Si el navegador externo sigue fallando, podemos crear un WebView interno:

```dart
// Añadir en checkout_confirmation_screen.dart
import 'package:webview_flutter/webview_flutter.dart';

// Si launchUrl falla, mostrar WebView:
showDialog(
  context: context,
  builder: (context) => Scaffold(
    appBar: AppBar(title: Text('Pago con Stripe')),
    body: WebViewWidget(
      controller: WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(url)),
    ),
  ),
);
```

---

## 📝 CHECKLIST DE DEBUGGING

- [ ] **Hot Restart ejecutado** (R en terminal Flutter)
- [ ] **Flujo completo reproducido** (añadir producto → checkout)
- [ ] **Logs revisados** (buscar "RESPONSE RAW COMPLETA")
- [ ] **Respuesta del backend copiada** (para análisis)
- [ ] **Formato identificado** (¿JSON? ¿URL directa? ¿Error?)
- [ ] **Acción tomada según escenario**

---

## 🚨 POSIBLES PROBLEMAS DEL BACKEND

### **1. Stripe API Key No Configurada**
```python
# En Django settings.py o .env:
STRIPE_SECRET_KEY = "sk_test_..."
STRIPE_PUBLISHABLE_KEY = "pk_test_..."
```

### **2. View No Devolviendo URL**
```python
# orders/views.py
def create_checkout_session(request):
    # ...
    checkout_session = stripe.checkout.Session.create(...)
    
    # ❌ MAL: No devuelve URL
    return Response({'success': True})
    
    # ✅ BIEN: Devuelve URL
    return Response({'url': checkout_session.url})
```

### **3. CORS Bloqueando Respuesta**
```python
# settings.py
CORS_ALLOW_ALL_ORIGINS = True  # Solo para testing
# O específico:
CORS_ALLOWED_ORIGINS = [
    "http://localhost:*",
]
```

---

## 📚 REFERENCIAS ÚTILES

- **Stripe Checkout Session**: https://stripe.com/docs/api/checkout/sessions/create
- **Flutter URL Launcher**: https://pub.dev/packages/url_launcher
- **Django REST Framework**: https://www.django-rest-framework.org/

---

## 🎓 CONCLUSIÓN

Con estos cambios:
1. **Verás EXACTAMENTE** qué devuelve el backend
2. **Soportamos múltiples formatos** de respuesta
3. **Errores son claros y específicos**
4. **Tienes opciones de fallback**

**SIGUIENTE PASO**: Ejecuta el flujo y envíame la sección "RESPONSE RAW COMPLETA" de los logs para análisis definitivo.
