# Correcciones Implementadas - Sistema de Carrito

## Fecha: 12 de Noviembre, 2025

### Problemas Identificados y Solucionados

#### ✅ 1. Carrito se vuelve "vacío" al modificar cantidades
**Causa:** `CartProvider` no actualizaba el estado local `_cart` con la respuesta del backend.

**Solución:** 
- Modificado `updateQuantity()`, `removeItem()`, y `clearCart()` para asignar directamente la respuesta del backend a `_cart`
- Eliminado flag `_isLoading` innecesario que causaba flickering
- Estado se actualiza inmediatamente después de cada operación

**Archivos modificados:**
- `lib/providers/cart_provider.dart`

---

#### ✅ 2. Errores 401 "fantasma" al reabrir la app
**Causa:** Token de acceso expirado sin refresh automático.

**Solución:**
- Creado `AuthenticatedHttpClient` que intercepta errores 401
- Intenta refresh automático del token (una sola vez)
- Reintenta la request original con el nuevo token
- Cola de espera para evitar múltiples refreshes simultáneos

**Archivos creados:**
- `lib/services/authenticated_http_client.dart`

**Nota:** Pendiente integrar en servicios (CartService, ProductService, OrderService)

---

#### ✅ 3. Múltiples cargas simultáneas del carrito
**Causa:** Navegación entre tabs disparaba múltiples llamadas a `loadCart()` en paralelo.

**Solución:**
- Agregado flag `_isLoadingCart` en `CartProvider`
- Verificación al inicio de `loadCart()` para omitir si ya hay carga en progreso
- Se usa `finally` para asegurar que el flag se resetea siempre

**Archivos modificados:**
- `lib/providers/cart_provider.dart`

---

#### ✅ 4. Carrito no se vacía al cerrar sesión
**Causa:** `AuthProvider.logout()` no limpiaba el estado del carrito.

**Solución:**
- Agregado `context.read<CartProvider>().reset()` antes de `logout()` en `ProfileScreen`
- Documentado en comentarios que CartProvider debe resetearse desde la UI

**Archivos modificados:**
- `lib/screens/profile_screen.dart`
- `lib/providers/auth_provider.dart` (documentación)

---

#### ✅ 5. Error 500 en checkout con mensaje poco claro
**Causa:** Errores del backend no tenían logs detallados ni manejo específico.

**Solución:**
- Agregados logs detallados en `createOrderFromCart()`:
  - URL del endpoint
  - Datos enviados (dirección, teléfono)
  - Status code de respuesta
  - Cuerpo de la respuesta en caso de error
  
- Agregados logs en `createStripeCheckoutSession()`:
  - Order ID usado
  - URL del endpoint Stripe
  - Respuesta completa del backend
  
- Manejo específico de errores:
  - 400: Error de validación (backend)
  - 401: Sesión expirada
  - 404: Orden no encontrada
  - 500: Error del servidor (config de Stripe)

**Archivos modificados:**
- `lib/services/order_service.dart`

---

#### ✅ 6. Mensajes de error genéricos en checkout
**Causa:** Errores solo mostraban SnackBar simple sin detalles.

**Solución:**
- Reemplazado SnackBar con AlertDialog detallado
- Muestra el mensaje de error completo
- Incluye sugerencias de troubleshooting:
  - Verificar que el carrito tenga productos
  - Validar datos de envío
  - Revisar conexión a internet
  - Verificar configuración de Stripe en backend
- Botón "Reintentar" que recarga el carrito

**Archivos modificados:**
- `lib/screens/cart_screen.dart`

---

## 🔍 Diagnóstico del Error 500 en Checkout

El error 500 ocurre en el backend al crear la sesión de Stripe. Posibles causas:

### Backend (Django):
1. **Configuración de Stripe:**
   - Verificar que `STRIPE_SECRET_KEY` esté configurada en settings.py
   - Verificar que `STRIPE_PUBLISHABLE_KEY` esté configurada
   - Ambas keys deben ser válidas y coincidir con el entorno (test/prod)

2. **Endpoint `/api/stripe/create-checkout-session/`:**
   - Verificar que el view existe y está registrado
   - Verificar que la orden existe antes de crear la sesión
   - Verificar que los line_items se generan correctamente

3. **Datos requeridos:**
   - `shipping_address` y `shipping_phone` son requeridos
   - El carrito debe tener items válidos
   - Los productos deben tener precio > 0

### Flutter:
- Los datos se están enviando correctamente (ahora con logs)
- La dirección y teléfono se validan antes de enviar
- El Order ID se obtiene correctamente del paso anterior

---

## 📋 Pasos para Probar las Correcciones

### Test 1: Modificación de cantidades
1. Iniciar sesión
2. Agregar 2-3 productos al carrito
3. Ir a la pantalla del carrito
4. ✅ Incrementar cantidad de un producto
5. ✅ Verificar que el carrito NO se vuelve vacío
6. ✅ Navegar a otra tab (Catálogo)
7. ✅ Volver a Carrito y verificar que los productos siguen ahí
8. ✅ Decrementar cantidad
9. ✅ Verificar actualización correcta

### Test 2: Logout y carrito vacío
1. Con productos en el carrito
2. Ir a Perfil
3. ✅ Cerrar sesión
4. ✅ Verificar que el carrito se limpió
5. Iniciar sesión nuevamente
6. ✅ Verificar que el carrito está vacío (o con el carrito del backend si hay)

### Test 3: Errores 401 al reabrir
1. Cerrar completamente la app
2. Esperar 5-10 minutos (para que expire el token)
3. ✅ Reabrir la app
4. ✅ Verificar que NO aparecen múltiples errores 401
5. ✅ Si aparece 401, debe solicitar relogin una sola vez

### Test 4: Checkout
1. Agregar productos al carrito
2. Ir a Carrito
3. Click en "Proceder al pago"
4. Llenar dirección y teléfono
5. ✅ Si hay error, verificar el AlertDialog con detalles
6. ✅ Revisar logs en consola para diagnóstico
7. Si error 500:
   - Revisar configuración de Stripe en backend
   - Verificar logs del backend Django

---

## 🚀 Próximos Pasos (Pendientes)

### Alta Prioridad:
1. **Integrar AuthenticatedHttpClient:**
   - Modificar CartService para usar el cliente
   - Modificar ProductService para usar el cliente
   - Modificar OrderService para usar el cliente
   - Esto eliminará los errores 401 automáticamente

2. **Resolver error 500 del backend:**
   - Revisar configuración de Stripe en Django
   - Agregar más logs en el backend para diagnóstico
   - Verificar que el endpoint `/api/stripe/create-checkout-session/` funciona

### Media Prioridad:
3. **Mejorar experiencia de usuario:**
   - Agregar loading indicator durante operaciones del carrito
   - Animaciones al agregar/quitar productos
   - Confirmación visual más clara

4. **Testing automatizado:**
   - Tests unitarios para CartProvider
   - Tests de integración para el flujo completo

---

## 📝 Notas Técnicas

### AuthenticatedHttpClient
El wrapper está listo pero NO integrado aún. Para usarlo:

```dart
// En un service:
final authClient = AuthenticatedHttpClient(authProvider: authProvider);

// Hacer request con retry automático:
final response = await authClient.get(
  Uri.parse('$baseUrl/cart/'),
  timeout: Duration(seconds: 15),
);
```

### CartProvider - Flag de carga
```dart
bool _isLoadingCart = false; // Evita cargas simultáneas

Future<void> loadCart(String token) async {
  if (_isLoadingCart) return; // Sale temprano si ya está cargando
  _isLoadingCart = true;
  try {
    // ...cargar datos
  } finally {
    _isLoadingCart = false; // Siempre resetea
  }
}
```

### Manejo de estado en operaciones
```dart
// ANTES (incorrecto):
_isLoading = true;
_cart = await service.updateItem(...);
_isLoading = false;
// ❌ Problema: entre las líneas, _cart podía estar null

// AHORA (correcto):
final updatedCart = await service.updateItem(...);
_cart = updatedCart; // ✅ Asignación atómica
notifyListeners();
```

---

## 🐛 Debugging

Si siguen apareciendo problemas:

### 1. Errores 401 persistentes:
```bash
# En Flutter logs:
flutter logs | grep "401\|refresh\|Token"
```
Buscar:
- "🔄 Token expirado (401), intentando refresh..."
- "❌ Falló el refresh del token"

### 2. Carrito vacío después de operaciones:
```bash
# En Flutter logs:
flutter logs | grep "🛒\|✅ Cantidad\|Items restantes"
```
Verificar que después de cada operación aparece:
- "✅ Cantidad actualizada. Items: X"
- "✅ Item eliminado. Items restantes: X"

### 3. Error 500 en checkout:
```bash
# En backend Django:
tail -f /var/log/gunicorn/error.log
# o
python manage.py runserver --verbosity 2
```
Buscar:
- Errores de Stripe API
- KeyError: 'STRIPE_SECRET_KEY'
- Excepciones no capturadas en views

---

## ✅ Checklist de Verificación

Antes de marcar como "funciona todo":

- [ ] Carrito se actualiza correctamente al incrementar/decrementar
- [ ] Carrito persiste al navegar entre tabs
- [ ] Carrito se vacía automáticamente al logout
- [ ] No aparecen múltiples errores 401 al reabrir app
- [ ] Mensajes de error son claros y útiles
- [ ] Checkout funciona (o muestra error claro si falla)
- [ ] Logs en consola son suficientes para debugging
- [ ] No hay memory leaks (revisar con DevTools)

---

## 📞 Contacto

Si persisten problemas después de estas correcciones:

1. Captura logs completos de Flutter (desde inicio hasta error)
2. Captura logs del backend Django (si hay acceso)
3. Describe el flujo exacto que causa el error
4. Incluye screenshots o video si es posible

---

**Última actualización:** 12 de Noviembre, 2025
**Autor:** GitHub Copilot
**Versión:** 1.0
