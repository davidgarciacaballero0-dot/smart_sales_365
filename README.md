
🗺️ Plan de Desarrollo Actualizado

✅ Fase 1: Configuración y Cimientos

Hecho (✅): Proyecto Flutter creado y estructura de carpetas organizada.

Hecho (✅): Paquetes instalados (provider, http, flutter_secure_storage, webview_flutter, intl, flutter_rating_bar, fl_chart).

Hecho (✅): Modelos de datos creados (Todos: Product, Brand, Category, CartItem, Order, OrderItem, Review).

Hecho (✅): Servicios de API separados (AuthService, ProductService, OrderService, AnalyticsService, CategoryBrandService).

Hecho (✅): Conexión a la API de Render (en la nube) funcionando.

Hecho (✅): Permiso de INTERNET configurado en Android.


✅ Fase 2: Vista de Cliente (El Escaparate)

Hecho (✅): Pantalla principal (HomeScreen) con navegación por pestañas (BottomNavigationBar).

Hecho (✅): Pestaña 1 ("Tienda") muestra el CatalogScreen (la cuadrícula de productos).

Hecho (✅): Funcionalidad de Búsqueda de productos en el catálogo.

Hecho (✅): Pantalla de Detalle de Producto (ProductDetailScreen).

Hecho (✅): Navegación (clic) desde la tarjeta del producto al detalle.

Hecho (✅): Visualización de detalles clave: imagen, precio, descripción y garantía.

✅ Fase 3: Autenticación y Perfil de Cliente

Hecho (✅): Flujo de "Login no obligatorio" implementado.

Hecho (✅): Pestaña 3 ("Mi Cuenta") que muestra LoginScreen (invitados) o UserProfileScreen (clientes).

Hecho (✅): Pantallas de LoginScreen y RegisterScreen funcionales.

Hecho (✅): Gestión de estado (AuthProvider) con tokens JWT de acceso y refresco.

Hecho (✅): Persistencia de sesión y botón de "Cerrar Sesión".

✅ Fase 4: Flujo de Compra (Carrito)

Hecho (✅): CartProvider para manejar el estado global del carrito.

Hecho (✅): Botón "Añadir al Carrito" en la pantalla de detalle.

Hecho (✅): Pestaña 2 ("Carrito") funcional: muestra ítems, cantidades, total y botón de eliminar.

Hecho (✅): Lógica para crear el pedido (POST a /api/orders/create/).

Hecho (✅): Integración de Stripe con WebView para el pago.

Hecho (✅): Corregidos errores 401 (Bearer) y UTF-8 en el flujo de pago.

Hecho (✅): Flujo de pago exitoso (cierre de WebView, diálogo de "¡Pago Exitoso!" y limpieza del carrito).

✅ Fase 5: Funciones Post-Compra (Cliente)

Hecho (✅): Pantalla de "Historial de Pedidos" (OrderHistoryScreen) creada y conectada al perfil del usuario.

Hecho (✅): Pantalla de "Detalle de Pedido" (OrderDetailScreen) creada y conectada.

Hecho (✅): Mostrar el comprobante de pago (recibo HTML) usando un WebView.

Hecho (✅): Funcionalidad completa para ver y escribir reseñas (con estrellas) en la pantalla de detalle del producto.

✅ Fase 6: Vistas de Administrador

Hecho (✅): Implementar la navegación por rol (detectar isAdmin en AuthProvider y redirigir con AuthWrapper).

Hecho (✅): Crear un Dashboard de Administrador (AdminDashboardScreen) con gráfico de predicciones de ventas.

Hecho (✅): Crear las vistas de Gestión (CRUD) para Productos (Crear, Ver, Editar, Eliminar).

Hecho (✅): Crear las vistas de Gestión (CRUD) para Categorías y Marcas (Crear, Ver, Editar, Eliminar).

📝 Fase 7: Extras (Pendiente)
Pendiente (📝): Configurar Notificaciones Push (mencionado en tu documento PDF).


