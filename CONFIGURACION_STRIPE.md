# 🔐 Configuración de Variables de Entorno para Stripe

## ⚠️ IMPORTANTE: Variables Requeridas

Sí, **NECESITAS configurar variables de entorno** en el backend de Cloud Run para que Stripe funcione correctamente.

---

## 📋 Variables de Entorno Necesarias

### 🔑 1. STRIPE_SECRET_KEY (OBLIGATORIA)
- **Descripción**: Clave secreta de Stripe para autenticar peticiones desde el servidor
- **Dónde obtenerla**: [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
- **Formato**: `sk_test_...` (modo prueba) o `sk_live_...` (modo producción)
- **Ejemplo**: `sk_test_51AbCdEf12345678901234567890GhIjKlMnOpQrStUvWxYz`

```bash
STRIPE_SECRET_KEY=sk_test_tu_clave_secreta_aqui
```

---

### 🔓 2. STRIPE_PUBLISHABLE_KEY (OBLIGATORIA)
- **Descripción**: Clave pública de Stripe para el frontend (aunque tu app no la use directamente en Django)
- **Dónde obtenerla**: [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
- **Formato**: `pk_test_...` (modo prueba) o `pk_live_...` (modo producción)
- **Ejemplo**: `pk_test_51AbCdEf12345678901234567890GhIjKlMnOpQrStUvWxYz`

```bash
STRIPE_PUBLISHABLE_KEY=pk_test_tu_clave_publica_aqui
```

---

### 🔗 3. STRIPE_WEBHOOK_SECRET (OBLIGATORIA)
- **Descripción**: Secreto para validar webhooks de Stripe (asegura que las notificaciones vienen de Stripe)
- **Dónde obtenerla**: [Stripe Webhooks](https://dashboard.stripe.com/webhooks)
- **Formato**: `whsec_...`
- **Ejemplo**: `whsec_1234567890abcdefGHIJKLMNOPQRSTUVWXYZ`

#### ⚙️ Pasos para configurar el Webhook:
1. Ve a [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)
2. Clic en **"+ Agregar endpoint"**
3. URL del endpoint: `https://smartsales-backend-891739940726.us-central1.run.app/api/stripe/webhook/`
4. Selecciona eventos a escuchar:
   - ✅ `checkout.session.completed`
   - ✅ `payment_intent.payment_failed`
5. Copia el **webhook signing secret** que empieza con `whsec_`

```bash
STRIPE_WEBHOOK_SECRET=whsec_tu_webhook_secret_aqui
```

---

### 🎯 4. FRONTEND_CHECKOUT_SUCCESS_URL (OPCIONAL)
- **Descripción**: URL a donde redirigir después de un pago exitoso
- **Por defecto**: `http://localhost:3000/checkout/success?session_id={CHECKOUT_SESSION_ID}`
- **Tu frontend Flutter**: Probablemente no necesitas cambiar esto (depende de cómo manejes la redirección)

```bash
FRONTEND_CHECKOUT_SUCCESS_URL=https://tu-frontend.com/checkout/success?session_id={CHECKOUT_SESSION_ID}
```

---

### ❌ 5. FRONTEND_CHECKOUT_CANCEL_URL (OPCIONAL)
- **Descripción**: URL a donde redirigir si el usuario cancela el pago
- **Por defecto**: `http://localhost:3000/checkout/cancel`

```bash
FRONTEND_CHECKOUT_CANCEL_URL=https://tu-frontend.com/checkout/cancel
```

---

## 🚀 Cómo Configurar las Variables en Cloud Run

### Opción 1: Desde Google Cloud Console (Interfaz Web)

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Navega a **Cloud Run** → Selecciona tu servicio `smartsales-backend`
3. Clic en **"EDITAR Y DESPLEGAR NUEVA REVISIÓN"**
4. Scroll hasta **"Variables y secretos"**
5. Clic en **"+ AGREGAR VARIABLE"**
6. Agrega cada variable:
   ```
   STRIPE_SECRET_KEY = sk_test_...
   STRIPE_PUBLISHABLE_KEY = pk_test_...
   STRIPE_WEBHOOK_SECRET = whsec_...
   ```
7. Clic en **"DESPLEGAR"**

---

### Opción 2: Desde Google Cloud CLI (Comando)

```bash
gcloud run services update smartsales-backend \
  --region=us-central1 \
  --update-env-vars \
STRIPE_SECRET_KEY=sk_test_tu_clave_secreta,\
STRIPE_PUBLISHABLE_KEY=pk_test_tu_clave_publica,\
STRIPE_WEBHOOK_SECRET=whsec_tu_webhook_secret
```

---

### Opción 3: Usando Google Secret Manager (Recomendado para Producción)

Para mayor seguridad, usa **Secret Manager** en lugar de variables de entorno planas:

```bash
# 1. Crear secretos
echo "sk_test_tu_clave_secreta" | gcloud secrets create stripe-secret-key --data-file=-
echo "pk_test_tu_clave_publica" | gcloud secrets create stripe-publishable-key --data-file=-
echo "whsec_tu_webhook_secret" | gcloud secrets create stripe-webhook-secret --data-file=-

# 2. Dar permisos a Cloud Run
gcloud secrets add-iam-policy-binding stripe-secret-key \
  --member="serviceAccount:TU_SERVICE_ACCOUNT@cloudrun-sa.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# 3. Montar secretos en Cloud Run
gcloud run services update smartsales-backend \
  --region=us-central1 \
  --update-secrets=STRIPE_SECRET_KEY=stripe-secret-key:latest,\
STRIPE_PUBLISHABLE_KEY=stripe-publishable-key:latest,\
STRIPE_WEBHOOK_SECRET=stripe-webhook-secret:latest
```

---

## 📝 Código del Backend que Usa las Variables

En `smartsales_backend/settings.py` (líneas 240-252):

```python
# Stripe Configuration
STRIPE_PUBLISHABLE_KEY = os.environ.get('STRIPE_PUBLISHABLE_KEY', '')
STRIPE_SECRET_KEY = os.environ.get('STRIPE_SECRET_KEY', '')
STRIPE_WEBHOOK_SECRET = os.environ.get('STRIPE_WEBHOOK_SECRET', '')

# Configurar Stripe API key globalmente
stripe.api_key = STRIPE_SECRET_KEY
```

**⚠️ Sin estas variables configuradas:**
- ❌ `stripe.api_key` será una cadena vacía
- ❌ Las peticiones a Stripe fallarán con errores de autenticación
- ❌ Los webhooks no se validarán correctamente

---

## 🧪 Verificar que las Variables Están Configuradas

Después de desplegar, puedes verificar:

```bash
# Ver variables de entorno del servicio
gcloud run services describe smartsales-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

O accede a los logs de Cloud Run y busca errores de Stripe al iniciar el servicio.

---

## ✅ Checklist de Configuración

- [ ] **Obtener claves de Stripe**: `sk_test_...` y `pk_test_...`
- [ ] **Configurar webhook en Stripe Dashboard**
- [ ] **Copiar el webhook secret**: `whsec_...`
- [ ] **Configurar las 3 variables obligatorias en Cloud Run**
- [ ] **Redesplegar el servicio de Cloud Run**
- [ ] **Probar el flujo de checkout desde Flutter**
- [ ] **Verificar que los webhooks se reciben correctamente**

---

## 🔍 Cómo Obtener las Claves de Stripe

### Paso 1: Ir al Dashboard de Stripe
1. Visita: [https://dashboard.stripe.com/](https://dashboard.stripe.com/)
2. Inicia sesión (o crea una cuenta si no tienes)

### Paso 2: Obtener API Keys
1. En el menú lateral, clic en **"Developers" → "API keys"**
2. Verás dos claves:
   - **Publishable key**: `pk_test_...` (empieza con `pk_`)
   - **Secret key**: `sk_test_...` (empieza con `sk_`)
   
   > 🔒 Clic en "Reveal test key" para ver la clave secreta

### Paso 3: Configurar Webhook
1. En el menú lateral, clic en **"Developers" → "Webhooks"**
2. Clic en **"+ Add endpoint"**
3. Endpoint URL: 
   ```
   https://smartsales-backend-891739940726.us-central1.run.app/api/stripe/webhook/
   ```
4. Selecciona eventos:
   - `checkout.session.completed`
   - `payment_intent.payment_failed`
5. Clic en **"Add endpoint"**
6. Copia el **Signing secret**: `whsec_...`

---

## 🎯 Modo Test vs Producción

### 🧪 Modo Test (Desarrollo)
- Claves comienzan con `sk_test_` y `pk_test_`
- No se cobran tarjetas reales
- Usa [tarjetas de prueba de Stripe](https://stripe.com/docs/testing#cards):
  - ✅ Éxito: `4242 4242 4242 4242`
  - ❌ Error: `4000 0000 0000 0002`

### 💳 Modo Producción (Live)
- Claves comienzan con `sk_live_` y `pk_live_`
- Se cobran tarjetas reales
- **Requiere activación de cuenta Stripe** (verificación de negocio)

---

## ❓ Preguntas Frecuentes

### ¿Puedo probar Stripe sin estas variables?
**NO**. El backend devolverá errores 500 porque `stripe.api_key` estará vacío.

### ¿Dónde veo los logs de errores de Stripe?
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=smartsales-backend" --limit=50 --format=json
```

### ¿Qué pasa si el webhook secret está mal?
Los webhooks de Stripe serán rechazados con error 400 "Invalid signature".

### ¿Necesito reiniciar Cloud Run después de configurar variables?
Cloud Run se redesplega automáticamente cuando cambias variables de entorno.

---

## 📚 Documentación Adicional

- [Stripe Dashboard](https://dashboard.stripe.com/)
- [Stripe API Keys Docs](https://stripe.com/docs/keys)
- [Stripe Webhooks Docs](https://stripe.com/docs/webhooks)
- [Google Cloud Run Environment Variables](https://cloud.google.com/run/docs/configuring/environment-variables)
- [Backend API Docs](https://smartsales-backend-891739940726.us-central1.run.app/api/docs/)

---

## 🎉 ¡Listo!

Una vez configuradas las variables, tu backend podrá:
✅ Crear sesiones de checkout de Stripe
✅ Procesar pagos con tarjetas
✅ Recibir webhooks de confirmación
✅ Actualizar el estado de órdenes automáticamente

**Siguiente paso**: Hacer hot restart en Flutter y probar el flujo completo de checkout.
