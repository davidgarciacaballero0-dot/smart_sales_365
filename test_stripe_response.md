# Test Stripe Response

## Problema Identificado

Del análisis de los logs:
1. ✅ Primera vez: Orden creada correctamente
2. ❌ Primera vez: Error "El backend no devolvió una URL de pago válida"
3. ❌ Segunda vez: Error "El carrito está vacío" (porque la primera orden lo vació)

**Conclusión**: La orden se crea exitosamente y vacía el carrito, pero la respuesta de Stripe no contiene la URL en ninguno de los 4 formatos esperados: `checkout_url`, `url`, `session_url`, `payment_url`.

## Siguiente Paso - Prueba Manual

Necesitamos ver la respuesta EXACTA del endpoint de Stripe. Para esto:

### Opción 1: Usando los nuevos logs mejorados

Con el código actualizado, ejecuta nuevamente el checkout. Ahora verás estos logs:
- `🚀 INICIO createOrderAndCheckout`
- `📋 PASO 1: Crear orden desde carrito`
- `✅ PASO 1 COMPLETADO: Orden ID X creada`
- `💳 PASO 2: Crear sesión de Stripe para orden X`
- `💳 Creando sesión de Stripe para orden ID: X`
- `📤 Request Body: {"order_id":X}`
- `📡 Status Code Stripe: XXX`
- `📦 Response Body RAW: {json completo}`

Copia todos estos logs y compártelos.

### Opción 2: Prueba directa con curl (si tienes acceso al backend)

```bash
# Primero obtén un token válido
curl -X POST https://smartsales-backend-891739940726.us-central1.run.app/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"pepe","password":"tu_password"}'

# Crea una orden (reemplaza TOKEN)
curl -X POST https://smartsales-backend-891739940726.us-central1.run.app/api/orders/create_order_from_cart/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"shipping_address":"Test","shipping_phone":"123"}'

# Llama al endpoint de Stripe (reemplaza TOKEN y ORDER_ID)
curl -X POST https://smartsales-backend-891739940726.us-central1.run.app/api/stripe/create-checkout-session/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"order_id":ORDER_ID}'
```

### Opción 3: Revisar código del backend

Busca el archivo que maneja `/api/stripe/create-checkout-session/` y revisa qué campo está retornando para la URL.

## Posibles Soluciones

Dependiendo de lo que encontremos, la solución será:

1. **Si el backend retorna otro nombre de campo** (ej: `stripe_url`, `checkout_link`, `payment_link`):
   - Agregar ese campo a la lista de intentos en `createStripeCheckoutSession`

2. **Si el backend retorna un objeto anidado** (ej: `{session: {url: "..."}}`):
   - Ajustar el código para acceder al campo anidado

3. **Si el backend retorna string directo** (no es objeto JSON):
   - Cambiar el parsing para manejar respuesta string

4. **Si el backend tiene error de configuración**:
   - Reportar al equipo backend para que corrijan la respuesta
