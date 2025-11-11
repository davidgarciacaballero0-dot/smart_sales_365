# 📱 Guía de Usuario - SmartSales365 Mobile

**Versión**: 2.0.0  
**Fecha**: 11 de noviembre de 2025

---

## 📖 Índice

1. [Introducción](#introducción)
2. [Primeros Pasos](#primeros-pasos)
3. [Guía para Clientes](#guía-para-clientes)
4. [Guía para Administradores](#guía-para-administradores)
5. [Funcionalidades Vanguardia](#funcionalidades-vanguardia)
6. [Preguntas Frecuentes](#preguntas-frecuentes)
7. [Solución de Problemas](#solución-de-problemas)
8. [Soporte](#soporte)

---

## 🎯 Introducción

**SmartSales365** es una aplicación móvil de comercio electrónico moderna que ofrece una experiencia completa tanto para clientes como para administradores. La aplicación incluye funcionalidades avanzadas como reconocimiento de voz, gestión de imágenes, y pagos seguros con Stripe.

### Características Principales

✅ **Para Clientes**:
- Catálogo de productos con búsqueda y filtros
- 🎤 Añadir productos al carrito por voz
- Carrito de compras sincronizado
- Checkout seguro con Stripe
- Historial de órdenes y recibos
- Sistema de reseñas y calificaciones

✅ **Para Administradores**:
- Dashboard con estadísticas en tiempo real
- Gestión completa de productos (CRUD)
- 📸 Carga de imágenes desde galería o cámara
- 🎤 Generación de reportes por voz con IA
- Gestión de usuarios, categorías y marcas
- Reportes en PDF, Excel y Word

---

## 🚀 Primeros Pasos

### 1. Instalación

#### Android
1. Descarga el archivo APK desde el enlace proporcionado
2. Habilita "Instalar aplicaciones de fuentes desconocidas" en Configuración
3. Abre el archivo APK y sigue las instrucciones de instalación
4. La app solicitará permisos (ver sección de permisos)

#### iOS
1. Descarga la app desde TestFlight o el App Store
2. Sigue las instrucciones de instalación
3. La app solicitará permisos (ver sección de permisos)

### 2. Permisos Necesarios

La aplicación solicitará los siguientes permisos:

| Permiso | Uso | Obligatorio |
|---------|-----|-------------|
| 🎤 **Micrófono** | Reconocimiento de voz para añadir productos y dictar reportes | Opcional |
| 📷 **Cámara** | Capturar fotos de productos (solo admin) | Opcional |
| 🖼️ **Galería** | Seleccionar imágenes de productos (solo admin) | Opcional |
| 🌐 **Internet** | Conectar con el backend y procesar pagos | **Requerido** |

> **Nota**: Puedes denegar los permisos opcionales, pero algunas funcionalidades no estarán disponibles.

### 3. Registro de Cuenta

1. Abre la aplicación
2. Toca **"Registrarse"** en la pantalla de inicio
3. Completa el formulario:
   - **Usuario**: Nombre de usuario único
   - **Email**: Correo electrónico válido
   - **Contraseña**: Mínimo 8 caracteres
   - **Nombre** y **Apellido**: Datos personales
4. Toca **"Registrar"**
5. Serás redirigido automáticamente a la pantalla de inicio de sesión

### 4. Inicio de Sesión

1. Ingresa tu **usuario** o **email**
2. Ingresa tu **contraseña**
3. Toca **"Iniciar Sesión"**
4. La app te llevará a tu pantalla principal según tu rol:
   - **Cliente** → Catálogo de productos
   - **Administrador** → Dashboard administrativo

---

## 🛍️ Guía para Clientes

### 📦 Explorar el Catálogo

#### Navegación Básica

1. **Vista Principal**:
   - Los productos se muestran en una cuadrícula
   - Cada tarjeta muestra: imagen, nombre, precio, stock y calificación

2. **Buscar Productos**:
   - Toca el campo de búsqueda en la parte superior
   - Escribe el nombre del producto
   - Los resultados se filtran automáticamente (con debounce de 500ms)

3. **Aplicar Filtros**:
   - Toca el ícono de filtro (☰) en la esquina superior derecha
   - Selecciona **Categoría** (Electrónica, Ropa, etc.)
   - Selecciona **Marca** (Samsung, Nike, etc.)
   - Toca **"Aplicar Filtros"**
   - Para limpiar: toca **"Limpiar Filtros"**

4. **Cargar Más Productos**:
   - Desliza hacia abajo para ver más productos
   - La app carga automáticamente la siguiente página

#### 🎤 Añadir Productos por Voz (NUEVO)

¡Ahora puedes añadir productos al carrito usando tu voz!

1. Toca el ícono del **micrófono** 🎤 en la barra superior
2. Concede el permiso de micrófono si es la primera vez
3. El ícono se volverá **rojo** cuando esté escuchando
4. Di el nombre del producto claramente:
   - Ejemplo: *"iPhone 14"*
   - Ejemplo: *"Zapatillas Nike"*
   - Ejemplo: *"Laptop HP"*
5. La app:
   - Buscará el producto automáticamente
   - Lo añadirá al carrito (cantidad: 1)
   - Mostrará una confirmación en pantalla

**Consejos**:
- Habla claramente y a velocidad normal
- Di solo el nombre del producto (sin cantidad)
- Si no se encuentra, aparecerá un mensaje de error
- Puedes cancelar tocando el ícono del micrófono nuevamente

---

### 🔍 Ver Detalle de Producto

1. Toca cualquier producto del catálogo
2. Verás la información completa:
   - **Imagen** grande del producto
   - **Nombre** y **Precio**
   - **Descripción** detallada
   - **Garantía** (si aplica)
   - **Reseñas** de otros clientes

#### Añadir al Carrito (Método Manual)

1. En la pantalla de detalle del producto
2. Toca el botón **"Añadir al Carrito e Ir"** en la parte inferior
3. El producto se añadirá automáticamente
4. Serás redirigido a la pestaña del carrito

---

### ⭐ Dejar una Reseña

1. Ve al detalle de un producto
2. Desliza hacia abajo hasta la sección **"Reseñas de Clientes"**
3. Toca **"Escribir una reseña"**
4. Selecciona una calificación (1-5 estrellas)
5. Escribe un comentario (opcional)
6. Toca **"Publicar"**

**Nota**: Solo puedes dejar una reseña por producto si estás autenticado.

---

### 🛒 Gestionar el Carrito

#### Ver el Carrito

1. Toca la pestaña **"Carrito"** en la barra inferior
2. Verás todos los productos añadidos con:
   - Imagen, nombre, precio unitario
   - Cantidad actual
   - Subtotal por producto

#### Modificar Cantidades

- **Aumentar cantidad**: Toca el botón **+**
- **Disminuir cantidad**: Toca el botón **-**
- Los cambios se sincronizan automáticamente con el servidor

#### Eliminar Productos

1. Toca el ícono de **basura** 🗑️ junto al producto
2. Confirma la eliminación

#### Vaciar el Carrito Completo

1. Toca **"Vaciar Carrito"** en la parte inferior
2. Confirma la acción
3. Todos los productos serán eliminados

---

### 💳 Realizar el Checkout

#### Proceso de Pago

1. En la pantalla del carrito, revisa tu pedido
2. Verifica el **Total** (suma de todos los productos)
3. Toca el botón **"Procesar Checkout"**
4. Se abrirá automáticamente tu **navegador web** 🌐
5. Serás redirigido a **Stripe Checkout** (plataforma de pagos segura)
6. Completa los datos de pago:
   - Número de tarjeta
   - Fecha de vencimiento
   - CVC
   - Información de facturación
7. Toca **"Pagar"**
8. Si el pago es exitoso:
   - Recibirás una confirmación
   - El navegador se cerrará automáticamente
   - Volverás a la app
   - Tu carrito se vaciará

**Notas de Seguridad**:
- SmartSales365 **NO almacena** tus datos de tarjeta
- Todos los pagos se procesan por **Stripe** (certificado PCI DSS)
- La conexión es segura (HTTPS)

---

### 📋 Historial de Órdenes

#### Ver tus Pedidos

1. Toca la pestaña **"Órdenes"** en la barra inferior
2. Verás una lista de todos tus pedidos con:
   - Número de orden
   - Fecha de compra
   - Estado (Pendiente, Procesando, Completada, Cancelada)
   - Monto total

#### Ver Detalle de una Orden

1. Toca cualquier orden de la lista
2. Verás:
   - **Información general**: Número, fecha, estado, monto
   - **Productos comprados**: Lista con imágenes, nombres, cantidades y precios
   - **Totales**: Subtotal, impuestos (si aplica), total

#### Descargar Recibo

1. En el detalle de la orden
2. Toca **"Descargar Recibo PDF"** o **"Ver Recibo HTML"**
3. El archivo se descargará automáticamente
4. Se abrirá en tu visor de archivos

---

### 🚪 Cerrar Sesión

1. Toca el ícono de **perfil** o **menú** (⋮)
2. Selecciona **"Cerrar Sesión"**
3. Confirma la acción
4. Serás redirigido a la pantalla de inicio de sesión

---

## 👨‍💼 Guía para Administradores

### 📊 Dashboard

#### Vista General

Al iniciar sesión como administrador, verás el **Dashboard** con:

- **KPIs Principales**:
  - Total de ventas del mes
  - Número de pedidos
  - Productos más vendidos
  - Usuarios registrados

- **Gráficos**:
  - Ventas por mes (líneas)
  - Ventas por categoría (barras)

- **Accesos Rápidos**:
  - Gestionar Productos
  - Gestionar Categorías
  - Gestionar Marcas
  - Gestionar Usuarios
  - Generar Reportes

---

### 📦 Gestión de Productos

#### Listar Productos

1. Desde el Dashboard, toca **"Gestionar Productos"**
2. Verás la lista completa de productos
3. Usa la búsqueda para filtrar por nombre
4. Cada producto muestra: imagen, nombre, precio, stock

#### Crear un Producto NUEVO

1. Toca el botón **+** (flotante) en la esquina inferior derecha
2. Completa el formulario:
   - **Nombre**: Nombre del producto (requerido)
   - **Descripción**: Descripción detallada (requerido)
   - **Precio**: Precio en bolivianos (requerido)
   - **Stock**: Cantidad disponible (requerido)
   - **Categoría**: Selecciona del desplegable (requerido)
   - **Marca**: Selecciona del desplegable (requerido)
   - **Garantía**: Duración en meses (opcional)

3. **📸 Añadir Imagen** (NUEVO):
   - Toca **"Seleccionar Imagen"**
   - Elige una opción:
     - **Galería**: Selecciona una foto existente
     - **Cámara**: Toma una foto nueva
   - La imagen se mostrará como preview
   - La app comprimirá automáticamente la imagen (1920x1080, 85% calidad)

4. Toca **"Guardar"**
5. El producto se creará y aparecerá en el catálogo

#### Editar un Producto

1. En la lista de productos, toca el producto que deseas editar
2. Toca el ícono de **edición** ✏️
3. Modifica los campos necesarios
4. **Cambiar Imagen** (NUEVO):
   - Toca **"Cambiar Imagen"**
   - Selecciona nueva imagen desde galería o cámara
   - El preview se actualizará
5. Toca **"Guardar"**

#### Eliminar un Producto

1. En la lista de productos, desliza el producto hacia la izquierda
2. Toca el ícono de **eliminar** 🗑️
3. Confirma la eliminación
4. El producto se eliminará permanentemente

**⚠️ Advertencia**: Esta acción no se puede deshacer.

---

### 🏷️ Gestión de Categorías

#### Listar Categorías

1. Desde el Dashboard, toca **"Gestionar Categorías"**
2. Verás todas las categorías con:
   - Nombre
   - Descripción
   - Número de productos asociados

#### Crear una Categoría

1. Toca el botón **+** (flotante)
2. Completa:
   - **Nombre**: Nombre de la categoría (ej: "Electrónica")
   - **Descripción**: Descripción breve (opcional)
3. Toca **"Guardar"**

#### Editar/Eliminar Categoría

- **Editar**: Toca la categoría → ícono de edición → modifica → Guardar
- **Eliminar**: Desliza la categoría → ícono de eliminar → Confirmar

**Nota**: No puedes eliminar una categoría que tenga productos asociados.

---

### 🏢 Gestión de Marcas

El proceso es idéntico al de categorías:

1. **Listar**: Dashboard → "Gestionar Marcas"
2. **Crear**: Botón + → Nombre y Descripción → Guardar
3. **Editar/Eliminar**: Mismos pasos que categorías

---

### 👥 Gestión de Usuarios

#### Listar Usuarios

1. Dashboard → **"Gestionar Usuarios"**
2. Verás todos los usuarios registrados con:
   - Nombre completo
   - Email
   - Rol (Cliente / Administrador)
   - Estado (Activo / Inactivo)

#### Editar Usuario

1. Toca el usuario que deseas editar
2. Puedes modificar:
   - **Datos personales**: Nombre, apellido, email
   - **Rol**: Cambiar entre Cliente y Administrador
   - **Estado**: Activar/Desactivar cuenta

3. Toca **"Guardar"**

**⚠️ Cuidado**: Cambiar un usuario a "Administrador" le dará acceso completo al panel admin.

#### Eliminar Usuario

1. Desliza el usuario hacia la izquierda
2. Toca el ícono de **eliminar** 🗑️
3. Confirma la eliminación

**Nota**: No puedes eliminar tu propia cuenta mientras estés autenticado.

---

### 📈 Generación de Reportes

#### Crear un Reporte con IA

1. Dashboard → **"Generar Reportes"**
2. Verás un campo de texto: **"Prompt del Reporte"**
3. Escribe lo que deseas consultar, por ejemplo:
   - *"Ventas totales del último mes"*
   - *"Productos más vendidos por categoría"*
   - *"Usuarios registrados esta semana"*
   - *"Análisis de inventario bajo"*

#### 🎤 Dictar el Prompt por Voz (NUEVO)

¡Ahora puedes dictar tu consulta usando tu voz!

1. Toca el ícono del **micrófono** 🎤 junto al campo de texto
2. Concede el permiso de micrófono si es la primera vez
3. El ícono se volverá **rojo** cuando esté escuchando
4. Di tu consulta claramente:
   - Ejemplo: *"Dame las ventas totales del último mes por categoría"*
   - Ejemplo: *"Muéstrame los productos con stock bajo"*
5. El texto reconocido aparecerá en el campo automáticamente
6. Revisa y edita si es necesario

#### Seleccionar Formato y Descargar

1. Selecciona el **formato** deseado:
   - **PDF**: Para visualización e impresión
   - **Excel**: Para análisis de datos
   - **Word**: Para edición y personalización

2. Toca **"Generar Reporte"**
3. La app procesará tu consulta con IA (puede tardar 5-10 segundos)
4. El archivo se descargará automáticamente
5. Se abrirá en la app correspondiente (lector PDF, Excel, etc.)

**Consejos para Mejores Resultados**:
- Sé específico en tu consulta
- Incluye rangos de fechas si es necesario
- Usa lenguaje natural (la IA entiende español)
- Si el reporte no es lo esperado, ajusta el prompt y vuelve a generar

---

## 🚀 Funcionalidades Vanguardia

SmartSales365 incluye **4 funcionalidades avanzadas** que mejoran la experiencia del usuario:

### 1. 🌐 URL Launcher para Stripe Checkout

**Qué hace**: Abre el proceso de pago en tu navegador nativo (Chrome, Safari, etc.) en lugar de un WebView interno.

**Beneficios**:
- Mayor seguridad (el navegador maneja los datos sensibles)
- Mejor rendimiento
- Autocompletado de datos de pago
- Sincronización con tu cuenta de Google/Apple Pay

**Cómo funciona**:
- Automático al tocar "Procesar Checkout"
- Si el navegador no puede abrirse, aparecerá un diálogo de error

---

### 2. 📸 Carga de Imágenes para Productos (Admin)

**Qué hace**: Permite a los administradores subir fotos de productos desde la galería o la cámara del dispositivo.

**Beneficios**:
- Catálogo más atractivo con imágenes reales
- Compresión automática (ahorra ancho de banda)
- Preview antes de subir

**Cómo funciona**:
- Al crear/editar producto: "Seleccionar Imagen" → Galería o Cámara
- La imagen se comprime a 1920x1080 píxeles, 85% calidad
- Upload multipart al servidor

**Requisitos**:
- Permiso de cámara (para tomar fotos)
- Permiso de galería (para seleccionar fotos)

---

### 3. 🎤 Añadir Productos al Carrito por Voz (Cliente)

**Qué hace**: Permite a los clientes añadir productos al carrito usando comandos de voz.

**Beneficios**:
- Compra más rápida y manos libres
- Accesibilidad mejorada
- Experiencia innovadora

**Cómo funciona**:
1. Toca el ícono de micrófono en el catálogo
2. Di el nombre del producto
3. La app busca el producto y lo añade al carrito
4. Confirmación visual y sonora

**Idioma**: Español (es_ES)

**Requisitos**:
- Permiso de micrófono
- Conexión a internet (para el reconocimiento de voz)

---

### 4. 🎤 Dictado de Reportes por Voz (Admin)

**Qué hace**: Permite a los administradores dictar el prompt del reporte en lugar de escribirlo.

**Beneficios**:
- Generación de reportes más rápida
- Menos errores de escritura
- Multitarea facilitada

**Cómo funciona**:
1. En la pantalla de reportes, toca el ícono de micrófono
2. Di tu consulta
3. El texto aparece en el campo automáticamente
4. Genera el reporte normalmente

**Idioma**: Español (es_ES)

**Requisitos**:
- Permiso de micrófono

---

## ❓ Preguntas Frecuentes

### General

**P: ¿Necesito cuenta para navegar el catálogo?**  
R: No, puedes ver los productos sin cuenta. Pero necesitas cuenta para añadir al carrito y comprar.

**P: ¿La app funciona sin internet?**  
R: No, necesitas conexión a internet para cargar productos, sincronizar el carrito y realizar pagos.

**P: ¿En qué dispositivos funciona?**  
R: Android 5.0+ (API 21) y iOS 12.0+

---

### Pagos y Seguridad

**P: ¿Es seguro pagar con Stripe?**  
R: Sí, Stripe es una plataforma certificada PCI DSS Level 1 (el más alto estándar de seguridad). SmartSales365 NO almacena tus datos de tarjeta.

**P: ¿Qué métodos de pago aceptan?**  
R: Stripe acepta tarjetas de crédito/débito (Visa, Mastercard, American Express), Apple Pay, Google Pay y más.

**P: ¿Puedo cancelar una orden?**  
R: Contacta con soporte inmediatamente después de realizar el pedido. Las órdenes en estado "Pendiente" pueden cancelarse.

---

### Funcionalidades de Voz

**P: ¿Por qué no funciona el reconocimiento de voz?**  
R: Verifica que:
- Hayas concedido el permiso de micrófono
- Tengas conexión a internet
- El micrófono de tu dispositivo funcione correctamente
- Estés hablando claramente y sin ruido de fondo

**P: ¿Funciona en otros idiomas además de español?**  
R: Actualmente solo soporta español (es_ES). Otros idiomas se añadirán en futuras versiones.

**P: ¿Por qué no encuentra el producto que digo?**  
R: Asegúrate de:
- Decir el nombre exacto del producto
- Que el producto exista en el catálogo
- Hablar claramente

---

### Imágenes

**P: ¿Qué formatos de imagen acepta?**  
R: JPG, PNG, HEIC (iOS). La app comprime automáticamente a JPG.

**P: ¿Cuál es el tamaño máximo de imagen?**  
R: Después de la compresión, generalmente < 2MB. No hay límite antes de la compresión.

**P: ¿Puedo subir múltiples imágenes por producto?**  
R: Actualmente solo 1 imagen por producto. Múltiples imágenes se añadirán en futuras versiones.

---

### Carrito y Órdenes

**P: ¿Mi carrito se guarda si cierro la app?**  
R: Sí, el carrito está sincronizado con el servidor. Se mantendrá entre sesiones (si no cierras sesión).

**P: ¿Puedo editar una orden después de pagar?**  
R: No, las órdenes no se pueden editar después del pago. Contacta con soporte para cambios.

**P: ¿Dónde están mis recibos?**  
R: En la sección "Órdenes" → Detalle de orden → "Descargar Recibo". También se envían por email.

---

### Administración

**P: ¿Cómo obtengo acceso de administrador?**  
R: Contacta con el propietario del sistema o el superadministrador para que te asigne el rol.

**P: ¿Puedo revertir un producto eliminado?**  
R: No, la eliminación es permanente. Ten cuidado al eliminar productos.

**P: ¿Los reportes con IA son precisos?**  
R: Los reportes se generan con datos reales de la base de datos. La IA solo ayuda a formatear y presentar la información.

---

## 🔧 Solución de Problemas

### La app no carga / Pantalla blanca

**Soluciones**:
1. Verifica tu conexión a internet
2. Cierra y vuelve a abrir la app
3. Borra el caché de la app (Configuración → Apps → SmartSales365 → Borrar caché)
4. Reinstala la app
5. Verifica que el servidor backend esté funcionando

---

### No puedo iniciar sesión

**Soluciones**:
1. Verifica que tu usuario/email y contraseña sean correctos
2. ¿Olvidaste tu contraseña? (contacta con soporte)
3. ¿Cuenta desactivada? (contacta con soporte)
4. Verifica tu conexión a internet
5. Intenta cerrar la app y volver a abrirla

---

### El pago no se procesa

**Soluciones**:
1. Verifica los datos de tu tarjeta
2. Asegúrate de tener fondos suficientes
3. Verifica que tu tarjeta acepte pagos internacionales (Stripe es de EE.UU.)
4. Intenta con otra tarjeta
5. Contacta con tu banco si el problema persiste

---

### El reconocimiento de voz no funciona

**Soluciones**:
1. Ve a Configuración del teléfono → Apps → SmartSales365 → Permisos
2. Activa el permiso de **Micrófono**
3. Verifica que tu conexión a internet funcione
4. Habla más cerca del micrófono
5. Reduce el ruido de fondo
6. Cierra y vuelve a abrir la app

---

### Las imágenes no se cargan

**Soluciones**:
1. Verifica tu conexión a internet
2. Las imágenes se cargan desde el servidor, ten paciencia
3. Si una imagen específica no carga, puede que no exista en el servidor
4. Intenta cerrar y volver a abrir la app
5. Borra el caché de la app

---

### Error al añadir al carrito

**Soluciones**:
1. Verifica que hayas iniciado sesión
2. Verifica tu conexión a internet
3. El producto puede estar agotado (stock = 0)
4. Intenta cerrar sesión y volver a iniciar sesión
5. Contacta con soporte si el error persiste

---

### El reporte no se genera / Demora mucho

**Soluciones**:
1. Los reportes con IA pueden tardar 5-15 segundos, ten paciencia
2. Verifica tu conexión a internet
3. Intenta con un prompt más simple
4. Si el error persiste, el servicio de IA puede estar caído (contacta con soporte)
5. Intenta generar el reporte en otro formato

---

## 📞 Soporte

### ¿Necesitas Ayuda?

Si tienes problemas que no están cubiertos en esta guía, contacta con nuestro equipo de soporte:

📧 **Email**: soporte@smartsales365.com  
📱 **Teléfono**: +591 XXX-XXXXX  
🕐 **Horario**: Lunes a Viernes, 9:00 - 18:00 (BOT)

---

### Reportar un Bug

Si encuentras un error en la app:

1. Toma una **captura de pantalla** del error
2. Anota los **pasos para reproducir** el error
3. Indica tu **dispositivo** (modelo, versión de Android/iOS)
4. Envía toda la información a: bugs@smartsales365.com

---

### Sugerencias y Feedback

¡Nos encantaría escuchar tus ideas!

💡 **Sugerencias**: feedback@smartsales365.com  
⭐ **Califica la app**: [Link a Google Play / App Store]

---

## 🎉 ¡Gracias por usar SmartSales365!

Esperamos que disfrutes de tu experiencia de compra. Esta guía se actualiza regularmente con nuevas funcionalidades.

**Última actualización**: 11 de noviembre de 2025  
**Versión de la guía**: 2.0.0

---

## 📚 Documentación Adicional

- [Plan de Refactorización](./REFACTORIZATION_PLAN.md) - Estado técnico del proyecto
- [README.md](./README.md) - Información para desarrolladores
- [Guía para Desarrolladores](./DEVELOPER_GUIDE.md) - Arquitectura y APIs

---

**© 2025 SmartSales365 - Universidad SISTEMAS DE INFORMACIÓN 2**
