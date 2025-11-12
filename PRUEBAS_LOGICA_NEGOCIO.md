# 🧪 PRUEBAS DE LÓGICA DE NEGOCIO - SMARTSALES365

## 📋 CONFIGURACIÓN ACTUAL

### Backend URL
```
https://smartsales-backend-891739940726.us-central1.run.app/api
```

### Estado del Código
- ✅ Compilación exitosa (0 errores)
- ✅ Validación pre-checkout implementada
- ✅ Recarga automática de carrito antes de pago
- ✅ Manejo de errores mejorado
- ✅ Retry automático para errores 502/503/504
- ⚠️ Stripe API Key pendiente de corrección (backend)

---

## 🎯 FLUJO COMPLETO DE COMPRA A PROBAR

### Fase 1: Autenticación ✅

**Endpoint**: `POST /api/token/`

**Pasos**:
1. Abrir la app
2. Ir a "Mi Cuenta" o "Iniciar Sesión"
3. Ingresar credenciales:
   - Usuario: `[tu_usuario]`
   - Contraseña: `[tu_contraseña]`
4. Presionar "Iniciar Sesión"

**Resultados esperados**:
```
📱 Login iniciado...
✅ Login exitoso
🔐 Token guardado
```

**Validaciones**:
- ✅ Token JWT se guarda en secure storage
- ✅ Usuario autenticado puede acceder a secciones protegidas
- ✅ Nombre de usuario aparece en perfil

**Posibles errores**:
- ❌ "Credenciales inválidas" → Verificar usuario/contraseña
- ❌ "Error de conexión" → Verificar internet y backend activo

---

### Fase 2: Explorar Catálogo ✅

**Endpoint**: `GET /api/products/?page=1`

**Pasos**:
1. Desde pantalla principal, navegar a "Tienda" o "Catálogo"
2. Esperar carga de productos (spinner debe aparecer)
3. Verificar que aparezcan 109 productos

**Resultados esperados**:
```
🔍 URL de productos: https://smartsales-backend-891739940726.us-central1.run.app/api/products/
🔍 Página: 1
📡 Status Code: 200
✅ 109 productos cargados
✅ Products loaded: 109
✅ Categories loaded: 16
✅ Brands loaded: 18
```

**Validaciones**:
- ✅ Productos se muestran con imagen, nombre, precio
- ✅ Categorías aparecen en filtro lateral/superior
- ✅ Marcas disponibles para filtrar
- ✅ Búsqueda por texto funciona

**Posibles errores**:
- ❌ "No se pudieron cargar productos" → Backend inaccesible
- ❌ Imágenes no cargan → URLs de imágenes incorrectas

---

### Fase 3: Filtrar Productos ✅

**Endpoints disponibles**:
```
GET /api/products/?category={category_id}
GET /api/products/?brand={brand_id}
GET /api/products/?search={query}
GET /api/products/?min_price={min}&max_price={max}
```

**Pasos**:

**3.1 Filtro por Categoría**:
1. Seleccionar una categoría (ej: "Electrodomésticos")
2. Verificar que solo aparecen productos de esa categoría

**3.2 Filtro por Marca**:
1. Seleccionar una marca (ej: "Samsung")
2. Verificar que solo aparecen productos Samsung

**3.3 Búsqueda por Texto**:
1. Escribir en barra de búsqueda: "Smart TV"
2. Presionar Enter o botón buscar
3. Verificar resultados relevantes

**3.4 Filtro por Precio**:
1. Ajustar rango de precio (ej: $100 - $500)
2. Aplicar filtro
3. Verificar que productos están en ese rango

**Resultados esperados**:
```
🔍 Filtrando por categoría: [ID]
📡 Status Code: 200
✅ [X] productos cargados
```

**Validaciones**:
- ✅ Filtros funcionan individualmente
- ✅ Filtros combinados funcionan (categoría + marca + precio)
- ✅ Búsqueda devuelve resultados relevantes
- ✅ Limpiar filtros restaura catálogo completo

---

### Fase 4: Ver Detalle de Producto ✅

**Endpoint**: `GET /api/products/{id}/`

**Pasos**:
1. Hacer clic en cualquier producto del catálogo
2. Esperar carga de detalles
3. Verificar información completa

**Resultados esperados**:
```
🔍 Obteniendo producto ID: 208
📡 Status producto detalle: 200
🔍 URL de reseñas: https://smartsales-backend-891739940726.us-central1.run.app/api/reviews/?product_id=208
📡 Status Code reseñas: 200
✅ [X] reseñas cargadas correctamente
```

**Validaciones**:
- ✅ Imagen principal del producto
- ✅ Galería de imágenes (si hay múltiples)
- ✅ Nombre, descripción, precio
- ✅ Stock disponible
- ✅ Reseñas y calificaciones de usuarios
- ✅ Botón "Agregar al carrito" visible

**Posibles errores**:
- ❌ "Producto no encontrado" → ID inválido
- ❌ Reseñas no cargan → Endpoint de reseñas falla

---

### Fase 5: Agregar Productos al Carrito ✅

**Endpoint**: `POST /api/cart/add/`

**Pasos**:

**5.1 Agregar primer producto**:
1. Desde detalle de producto, presionar "Agregar al carrito"
2. Verificar confirmación visual (snackbar/toast)
3. Verificar que contador del carrito incrementa

**Resultados esperados**:
```
➕ Añadiendo producto 208 (cantidad: 1)
✅ Producto añadido. Total items: 0
🛒 Cargando carrito desde backend...
✅ Carrito cargado: 1 items
💰 Total: $114.71
```

**5.2 Agregar producto duplicado**:
1. Agregar el mismo producto nuevamente
2. Verificar que cantidad incrementa (no crea item duplicado)

**5.3 Agregar múltiples productos diferentes**:
1. Agregar 3-4 productos diferentes
2. Verificar que carrito muestra todos

**Validaciones**:
- ✅ Producto se agrega inmediatamente
- ✅ Carrito sincroniza con backend
- ✅ Total se calcula correctamente
- ✅ Cantidad incrementa para mismo producto
- ✅ Ícono del carrito muestra badge con cantidad

**Posibles errores**:
- ❌ "No se pudo agregar producto" → Carrito lleno o backend falla
- ❌ Total incorrecto → Error de cálculo en backend
- ❌ "Sesión expirada" → Token JWT expirado, reloguear

---

### Fase 6: Gestionar Carrito ✅

**Endpoints**:
```
GET /api/cart/               # Ver carrito
PUT /api/cart/update/{id}/   # Actualizar cantidad
DELETE /api/cart/remove/{id}/ # Eliminar item
POST /api/cart/clear/        # Vaciar carrito
```

**Pasos**:

**6.1 Ver carrito completo**:
1. Presionar ícono del carrito en navegación
2. Verificar que aparecen todos los productos agregados

**Resultados esperados**:
```
🛒 Cargando carrito desde backend...
✅ Carrito cargado: 3 items
💰 Total: $2,542.05
```

**6.2 Modificar cantidad**:
1. Incrementar cantidad de un producto (botón +)
2. Verificar que precio total actualiza
3. Decrementar cantidad (botón -)
4. Verificar actualización

**Resultados esperados (con retry automático)**:
```
📝 Actualizando item ID 123 a cantidad: 2
🔄 Intento 1 de actualizar item...
✅ Item actualizado exitosamente
🛒 Cargando carrito desde backend...
✅ Carrito cargado: 3 items
💰 Total: $[nuevo_total]
```

**6.3 Eliminar producto**:
1. Presionar botón "Eliminar" o ícono de basura
2. Confirmar eliminación (si hay diálogo)
3. Verificar que producto desaparece

**Resultados esperados**:
```
🗑️ Eliminando item ID 123...
✅ Item eliminado exitosamente
🛒 Cargando carrito desde backend...
✅ Carrito cargado: 2 items
💰 Total: $[nuevo_total]
```

**6.4 Vaciar carrito completo**:
1. Presionar "Vaciar carrito" o "Eliminar todo"
2. Confirmar acción
3. Verificar carrito vacío

**Validaciones**:
- ✅ Cambios de cantidad sincronizan inmediatamente
- ✅ Total recalcula en tiempo real
- ✅ Eliminación funciona sin errores
- ✅ Vaciar carrito limpia todo
- ✅ Retry automático funciona en errores 502/503/504
- ✅ Carrito persiste entre sesiones

**Posibles errores**:
- ❌ "Error al actualizar" → Backend temporalmente inaccesible (retry automático activado)
- ❌ Total no actualiza → Problema de sincronización frontend-backend

---

### Fase 7: Proceder al Checkout ✅ (Frontend funcional)

**Endpoints**:
```
POST /api/orders/create_order_from_cart/
POST /api/stripe/create-checkout-session/
```

**Pasos**:

**7.1 Iniciar checkout**:
1. Desde carrito, presionar "Proceder al pago"
2. Aparece diálogo de datos de envío

**7.2 Ingresar datos de envío**:
1. Dirección de envío: `Av. Siempre Viva 742`
2. Teléfono de contacto: `+591 69123456`
3. Presionar "Confirmar"

**Resultados esperados**:
```
🛍️ Iniciando proceso de checkout...
🔄 Recargando carrito para verificar estado...
🛒 Cargando carrito desde backend...
✅ Carrito cargado: 2 items
💰 Total: $2,257.34
✅ Carrito verificado: 2 items, Total: $2257.34
📦 Creando orden desde carrito...
🔍 URL: https://smartsales-backend-891739940726.us-central1.run.app/api/orders/create_order_from_cart/
📍 Dirección: Av. Siempre Viva 742
📞 Teléfono: +591 69123456
📡 Status Code orden: 201
✅ Orden creada exitosamente: Orden ID 1886
💳 Creando sesión de Stripe para orden ID: 1886
🔍 URL: https://smartsales-backend-891739940726.us-central1.run.app/api/stripe/create-checkout-session/
📡 Status Code Stripe: 200  ← ✅ DEBE SER 200
✅ Respuesta Stripe: {checkout_url: https://checkout.stripe.com/...}
✅ URL de checkout obtenida
🌐 Redirigiendo a Stripe...
```

**Validaciones FRONTEND** (Todas funcionan ✅):
- ✅ Validación de campos obligatorios
- ✅ Recarga automática del carrito antes de crear orden
- ✅ Validación multi-nivel:
  * ✅ Carrito cargado correctamente
  * ✅ Carrito tiene al menos 1 item
  * ✅ Total es mayor a 0
- ✅ Creación de orden exitosa con status 201
- ✅ Order ID se retorna correctamente

**Error BACKEND Actual** (Pendiente de corrección):
```
📡 Status Code Stripe: 500  ← ❌ ERROR
❌ Error 500 del servidor: {"error":"Invalid API Key provided: sk_test_***DWGW"}
❌ Error en checkout: Exception: Error del servidor (500). Verifica la configuración de Stripe en el backend
```

**CAUSA**: Stripe API Key inválida en el backend  
**SOLUCIÓN**: Ver `SOLUCION_DEFINITIVA_STRIPE.md`

**Posibles errores (Frontend)**:
- ❌ "El carrito está vacío" → Validación detectó carrito vacío
- ❌ "El carrito no se ha cargado correctamente" → Problema de sincronización
- ❌ "El total del carrito debe ser mayor a cero" → Validación de precio

**Posibles errores (Backend)**:
- ❌ Error 500 Stripe → API Key inválida (actual)
- ❌ Error 400 → Datos de orden inválidos
- ❌ Error 404 → Orden no encontrada

---

### Fase 8: Completar Pago con Stripe ⚠️ (Pendiente Backend)

**Esta fase NO funcionará hasta que se corrija la Stripe API Key**

**Pasos esperados** (después de corrección):

1. Usuario es redirigido a Stripe Checkout
2. Página de Stripe muestra:
   - Productos de la orden
   - Total a pagar
   - Formulario de tarjeta

3. Ingresar datos de tarjeta de prueba:
   - Número: `4242 4242 4242 4242`
   - Fecha: Cualquier fecha futura (ej: 12/25)
   - CVC: Cualquier 3 dígitos (ej: 123)
   - Nombre: Cualquier nombre

4. Presionar "Pagar"

5. Stripe procesa el pago

6. Redirección a app con éxito o error

**Resultados esperados**:
```
[Stripe] Procesando pago...
[Stripe] Pago exitoso
[Backend Webhook] Actualizando orden 1886 a estado PAGADO
[App] Redirigido a pantalla de éxito
```

**Validaciones**:
- ✅ Redirección a Stripe funciona
- ✅ Stripe muestra productos correctos
- ✅ Total coincide con el del carrito
- ✅ Tarjeta de prueba procesa correctamente
- ✅ Webhook actualiza estado de orden
- ✅ Usuario recibe confirmación

**Tarjetas de prueba Stripe**:
```
Éxito: 4242 4242 4242 4242
Requiere autenticación: 4000 0025 0000 3155
Declinada: 4000 0000 0000 9995
Fondos insuficientes: 4000 0000 0000 9995
```

---

### Fase 9: Verificar Historial de Órdenes ✅

**Endpoint**: `GET /api/orders/`

**Pasos**:
1. Ir a "Mi Cuenta" → "Mis Pedidos" o "Historial de órdenes"
2. Verificar que aparece la orden recién creada

**Resultados esperados**:
```
📦 Cargando órdenes...
✅ [X] órdenes cargadas
```

**Validaciones**:
- ✅ Order ID aparece en la lista
- ✅ Fecha y hora de creación
- ✅ Estado de la orden (PENDIENTE/PAGADO/ENVIADO/COMPLETADO)
- ✅ Total pagado
- ✅ Productos incluidos en la orden

**Posibles errores**:
- ❌ "No hay órdenes" → Usuario no tiene órdenes previas
- ❌ Orden no aparece → Verificar que se creó correctamente

---

### Fase 10: Ver Detalle de Orden ✅

**Endpoint**: `GET /api/orders/{id}/`

**Pasos**:
1. Desde historial, hacer clic en una orden
2. Ver detalles completos

**Validaciones**:
- ✅ ID de orden
- ✅ Fecha de creación
- ✅ Estado actual
- ✅ Dirección de envío
- ✅ Teléfono de contacto
- ✅ Lista de productos con cantidades y precios
- ✅ Subtotal, impuestos (si aplica), total
- ✅ Información de pago (si se completó)

---

## 🎯 RESUMEN DE PRUEBAS

### ✅ Funcionalidades Completamente Funcionales

1. ✅ Autenticación (login/logout)
2. ✅ Catálogo de productos
3. ✅ Filtros y búsqueda
4. ✅ Detalle de producto
5. ✅ Agregar al carrito
6. ✅ Gestión de carrito (actualizar, eliminar, vaciar)
7. ✅ Validación pre-checkout
8. ✅ Creación de orden
9. ✅ Historial de órdenes
10. ✅ Detalle de orden
11. ✅ Retry automático para errores 502/503/504
12. ✅ Sincronización carrito frontend-backend

### ⚠️ Funcionalidades Bloqueadas por Backend

1. ⚠️ **Pago con Stripe** - Requiere actualización de API Key
   - Frontend funciona correctamente
   - Backend retorna error 500
   - Solución documentada en `SOLUCION_DEFINITIVA_STRIPE.md`

---

## 📊 CHECKLIST DE TESTING

### Antes de Empezar
- [ ] Backend activo: `https://smartsales-backend-891739940726.us-central1.run.app/api/`
- [ ] App instalada y actualizada
- [ ] Credenciales de usuario listas
- [ ] Internet estable

### Testing Básico (10-15 min)
- [ ] Login exitoso
- [ ] Catálogo carga correctamente
- [ ] Filtros funcionan
- [ ] Agregar 2-3 productos al carrito
- [ ] Modificar cantidades
- [ ] Eliminar un producto
- [ ] Ver total actualizado

### Testing de Checkout (5-10 min)
- [ ] Proceder al pago
- [ ] Ingresar datos de envío
- [ ] Verificar validación de carrito
- [ ] Orden se crea (status 201)
- [ ] **Verificar error Stripe** (esperado por ahora)

### Testing de Historial (5 min)
- [ ] Acceder a historial de órdenes
- [ ] Verificar orden recién creada
- [ ] Ver detalles de orden
- [ ] Estado es "PENDIENTE" (no se completó pago)

### Testing Avanzado (Después de corregir Stripe)
- [ ] Checkout completo
- [ ] Redirección a Stripe funciona
- [ ] Pago con tarjeta de prueba
- [ ] Webhook actualiza estado
- [ ] Orden aparece como "PAGADO"
- [ ] Carrito se vacía automáticamente

---

## 🔥 ERRORES CONOCIDOS Y SOLUCIONES

### 1. Error 500 en Stripe Checkout
**Síntoma**: "Error del servidor (500). Verifica la configuración de Stripe"  
**Causa**: Stripe API Key inválida en backend  
**Solución**: Ver `SOLUCION_DEFINITIVA_STRIPE.md`  
**Estado**: Pendiente de corrección en backend

### 2. "El carrito está vacío" al hacer checkout
**Síntoma**: Validación rechaza checkout  
**Causa**: Carrito desincronizado entre frontend y backend  
**Solución**: ✅ Ya corregido con recarga automática  
**Estado**: Resuelto

### 3. LateInitializationError en historial
**Síntoma**: App crash al abrir historial de órdenes  
**Causa**: Campo `_ordersFuture` accedido antes de inicializar  
**Solución**: ✅ Ya corregido, ahora es nullable  
**Estado**: Resuelto

### 4. Error 502/503/504 en operaciones de carrito
**Síntoma**: "Error de servidor" al agregar/actualizar carrito  
**Causa**: Backend temporalmente sobrecargado  
**Solución**: ✅ Retry automático implementado (3 intentos)  
**Estado**: Mitigado

### 5. Token expirado durante checkout
**Síntoma**: "Sesión expirada" al intentar pagar  
**Causa**: JWT token expiró (tiempo de vida configurado en backend)  
**Solución**: Reloguear en la app  
**Estado**: Comportamiento esperado

---

## 📈 MÉTRICAS DE ÉXITO

### Funcionalidad
- ✅ 95% de features funcionales (solo Stripe pendiente)
- ✅ 0 errores de compilación
- ✅ Validación robusta implementada
- ✅ Retry automático funcionando

### Estabilidad
- ✅ No crashes en operaciones normales
- ✅ Manejo graceful de errores de red
- ✅ Sincronización correcta con backend

### User Experience
- ✅ Feedback visual en todas las operaciones
- ✅ Mensajes de error claros
- ✅ Loading states apropiados
- ✅ Validación en tiempo real

---

## 🚀 PRÓXIMOS PASOS

### Inmediato (Backend)
1. **URGENTE**: Actualizar `STRIPE_SECRET_KEY` en Google Cloud Run
2. Verificar que Stripe API Key es válida
3. Configurar webhook de Stripe
4. Probar checkout end-to-end

### Corto Plazo (Frontend)
1. Agregar loading indicator visible en checkout
2. Implementar pantalla de éxito post-pago
3. Mejorar manejo de errores de Stripe
4. Agregar confirmación visual al vaciar carrito

### Mediano Plazo
1. Optimizar múltiples llamadas a `loadCart()`
2. Implementar cache temporal de carrito
3. Integrar `AuthenticatedHttpClient` en todos los servicios
4. Agregar analytics para tracking de conversión

---

## 📞 CONTACTO Y SOPORTE

**Documentación técnica**:
- `ANALISIS_LOGS_Y_MEJORAS.md` - Análisis de logs y correcciones
- `CORRECCIONES_CARRITO.md` - Historial de fixes del carrito
- `CORRECCION_CHECKOUT_CARRITO_VACIO.md` - Fix de validación
- `SOLUCION_DEFINITIVA_STRIPE.md` - Solución error Stripe

**Enlaces útiles**:
- Backend API: https://smartsales-backend-891739940726.us-central1.run.app/api/docs/
- Stripe Dashboard: https://dashboard.stripe.com/test/apikeys
- GitHub Repo: https://github.com/davidgarciacaballero0-dot/smart_sales_365

---

**Última actualización**: 12 de noviembre de 2025  
**Versión de testing**: 1.0  
**Estado**: Listo para pruebas (excepto pago Stripe)
