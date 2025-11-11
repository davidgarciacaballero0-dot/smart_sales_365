# 🔧 Plan de Refactorización Completo - SmartSales365 Mobile

## 🚨 **PROBLEMA CRÍTICO: Backend NO Disponible**

### Estado Actual del Backend
- **URL Configurada**: `https://smartsales-backend-891739940726.us-central1.run.app/api`
- **Estado**: ❌ **NO DISPONIBLE** (404 en todos los endpoints)
- **Documentación**: ❌ `/api/docs/` también devuelve 404

### ✅ Soluciones Inmediatas

#### **Opción 1: Levantar Backend Localmente (RECOMENDADO)**
```powershell
# 1. Clonar repositorio del backend
git clone https://github.com/DiegoxdGarcia2/SmartSales-backend.git
cd SmartSales-backend

# 2. Crear entorno virtual
python -m venv venv
.\venv\Scripts\Activate.ps1

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Configurar base de datos
python manage.py migrate

# 5. Crear superusuario
python manage.py createsuperuser

# 6. Cargar datos de prueba (opcional)
python manage.py loaddata initial_data.json

# 7. Correr servidor
python manage.py runserver 0.0.0.0:8000
```

#### **Actualizar URL en la App Móvil**
```dart
// lib/services/api_service.dart
class ApiService {
  // Para dispositivo físico Android (reemplaza con tu IP local)
  final String baseUrl = 'http://192.168.1.XXX:8000/api';
  
  // Para emulador Android
  // final String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Para iOS Simulator
  // final String baseUrl = 'http://localhost:8000/api';
}
```

---

## 📊 **Análisis Completo del Backend**

### Estructura de URLs Confirmada (según GitHub)

#### **1. Autenticación** (`/api/`)
```python
POST   /api/token/                      # Login (JWT) ✅
POST   /api/token/refresh/              # Refresh token ✅
POST   /api/users/register/             # Registro ✅
```

**Respuesta de Login** (según `MyTokenObtainPairSerializer`):
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "role": "ADMINISTRADOR"
  }
}
```

#### **2. Usuarios** (`/api/users/`)
```python
GET    /api/users/users/               # Listar usuarios (admin: todos, user: solo propio)
GET    /api/users/users/{id}/          # Obtener usuario específico
PUT    /api/users/users/{id}/          # Actualizar usuario
POST   /api/users/users/               # Crear usuario (solo admin)
DELETE /api/users/users/{id}/          # Eliminar usuario (solo admin)

GET    /api/users/profiles/            # Listar perfiles
GET    /api/users/profiles/{id}/       # Obtener perfil
PUT    /api/users/profiles/{id}/       # Actualizar perfil
POST   /api/users/profiles/            # Crear perfil

GET    /api/users/roles/               # Listar roles
```

**⚠️ NO EXISTE** `/api/users/me/` - En su lugar:
- Usar `GET /api/users/users/` que automáticamente filtra el usuario actual
- O usar `GET /api/users/users/{user_id}/` con el ID del usuario obtenido en el login

#### **3. Productos** (`/api/`)
```python
GET    /api/products/                  # Listar productos ✅
GET    /api/products/?category=1       # Filtrar por categoría ✅
GET    /api/products/?brand=2          # Filtrar por marca ✅
GET    /api/products/{id}/             # Obtener producto ✅
POST   /api/products/                  # Crear producto (admin)
PUT    /api/products/{id}/             # Actualizar producto (admin)
DELETE /api/products/{id}/             # Eliminar producto (admin)

GET    /api/categories/                # Listar categorías ✅
GET    /api/brands/                    # Listar marcas ✅

GET    /api/reviews/                   # Listar todas las reseñas
GET    /api/reviews/?product_id=1      # Filtrar reseñas por producto ✅
POST   /api/reviews/                   # Crear reseña ✅
PUT    /api/reviews/{id}/              # Actualizar reseña
DELETE /api/reviews/{id}/              # Eliminar reseña
```

#### **4. Carrito y Órdenes** (`/api/`)
```python
GET    /api/cart/                      # Obtener carrito del usuario ✅
POST   /api/cart/                      # Añadir item al carrito ✅
PUT    /api/cart/                      # Actualizar cantidad de item ✅
DELETE /api/cart/                      # Eliminar item del carrito ✅

GET    /api/orders/                    # Listar órdenes del usuario ✅
GET    /api/orders/{id}/               # Obtener detalle de orden ✅
POST   /api/orders/create_order_from_cart/  # Crear orden desde carrito ✅

POST   /api/stripe/create-checkout-session/  # Crear sesión de Stripe ✅
POST   /api/stripe/webhook/            # Webhook de Stripe

GET    /api/receipt/{order_id}/        # Obtener recibo HTML ✅
GET    /api/receipt/{order_id}/pdf/    # Descargar PDF del recibo ✅
```

#### **5. Analytics** (`/api/analytics/`)
```python
GET    /api/analytics/predictions/sales/monthly/  # Predicciones de ventas
GET    /api/analytics/sales_by_month/             # Histórico por mes
GET    /api/analytics/sales_by_category/          # Histórico por categoría
GET    /api/analytics/recommendations/frequently_bought_together/  # Recomendaciones
GET    /api/analytics/complementary_category_recs/  # Categorías complementarias
GET    /api/analytics/dashboard/kpis/             # KPIs del dashboard
```

---

## 🔍 **Problemas Identificados en la App Actual**

### 1. ❌ **AuthService** (`lib/services/auth_service.dart`)

#### Problema 1: Endpoint de perfil incorrecto
```dart
// ❌ INCORRECTO - Este endpoint NO existe
Future<UserProfile> getUserProfile(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/users/me/'),  // ❌ NO EXISTE
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
}
```

#### Solución:
```dart
// ✅ CORRECTO - Opción 1: Obtener lista (filtrada automáticamente)
Future<UserProfile> getUserProfile(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/users/users/'),  // ✅ Devuelve lista con usuario actual
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> users = jsonDecode(utf8.decode(response.bodyBytes));
    if (users.isNotEmpty) {
      return UserProfile.fromJson(users.first);  // Primer usuario (el actual)
    }
  }
  throw Exception('No se pudo obtener el perfil');
}

// ✅ CORRECTO - Opción 2: Usar ID del usuario del login
Future<UserProfile> getUserProfile(String token, int userId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/users/users/$userId/'),  // ✅ Usuario específico
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    return UserProfile.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }
  throw Exception('No se pudo obtener el perfil');
}
```

#### Problema 2: No se guarda el user_id del login
```dart
// ❌ El login actual solo retorna el token
Future<String?> login(String username, String password) async {
  // ...
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['access'];  // ❌ Solo guarda access token
  }
}
```

#### Solución:
```dart
// ✅ Retornar objeto con token Y datos de usuario
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserData user;
  
  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
  
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access'],
      refreshToken: json['refresh'],
      user: UserData.fromJson(json['user']),
    );
  }
}

class UserData {
  final int id;
  final String username;
  final String email;
  final String? role;
  
  UserData({
    required this.id,
    required this.username,
    required this.email,
    this.role,
  });
  
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
    );
  }
}

// ✅ Método de login mejorado
Future<LoginResponse> login(String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/token/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  ).timeout(const Duration(seconds: 15));

  if (response.statusCode == 200) {
    return LoginResponse.fromJson(jsonDecode(response.body));
  }
  throw Exception('Login falló');
}
```

### 2. ❌ **ProductService** (`lib/services/product_service.dart`)

#### Problema: Inconsistencia en manejo de respuestas
```dart
// El método actual asume que la respuesta es un array directo
Future<List<Product>> getProducts(...) async {
  if (response.statusCode == 200) {
    List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
    // ❌ ¿Y si el backend usa paginación con {results: [...], count: X}?
  }
}
```

#### Solución: Manejar ambos formatos
```dart
Future<ProductsResponse> getProducts({
  String? token,
  Map<String, dynamic>? filters,
  int page = 1,
}) async {
  // Añadir parámetro de página si existe paginación
  final finalFilters = filters ?? {};
  if (page > 1) {
    finalFilters['page'] = page.toString();
  }
  
  Uri uri = Uri.parse('$baseUrl/$_productsPath/');
  if (finalFilters.isNotEmpty) {
    uri = uri.replace(
      queryParameters: finalFilters.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  final response = await http.get(uri, headers: headers);

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
    
    // Manejar respuesta paginada o array directo
    if (jsonData is Map && jsonData.containsKey('results')) {
      // Respuesta paginada: {count: X, next: URL, previous: URL, results: [...]}
      return ProductsResponse(
        products: (jsonData['results'] as List)
            .map((item) => Product.fromJson(item))
            .toList(),
        count: jsonData['count'],
        next: jsonData['next'],
        previous: jsonData['previous'],
      );
    } else {
      // Array directo
      return ProductsResponse(
        products: (jsonData as List)
            .map((item) => Product.fromJson(item))
            .toList(),
      );
    }
  }
  throw Exception('Error al cargar productos');
}

class ProductsResponse {
  final List<Product> products;
  final int? count;
  final String? next;
  final String? previous;
  
  ProductsResponse({
    required this.products,
    this.count,
    this.next,
    this.previous,
  });
}
```

### 3. ✅ **OrderService** - Parece correcto pero verificar

Endpoints a verificar:
- ✅ `POST /api/orders/create_order_from_cart/` 
- ✅ `POST /api/stripe/create-checkout-session/`
- ✅ `GET /api/orders/`
- ✅ `GET /api/receipt/{order_id}/`

---

## 📝 **Plan de Refactorización Paso a Paso**

### **PASO 0: Levantar Backend** ⚠️ **OBLIGATORIO**
```powershell
# En directorio del backend
python manage.py runserver 0.0.0.0:8000

# Verificar que responde:
# http://localhost:8000/admin/
# http://localhost:8000/api/products/
```

### **PASO 1: Actualizar API Service**
```dart
// lib/services/api_service.dart
class ApiService {
  // Cambiar según donde corra el backend
  final String baseUrl = 'http://192.168.1.XXX:8000/api';  // Tu IP local
  // final String baseUrl = 'http://10.0.2.2:8000/api';  // Emulador
  
  // ... resto del código
}
```

### **PASO 2: Refactorizar AuthService**

1. Crear modelos de respuesta:
   - `LoginResponse` (access, refresh, user)
   - `UserData` (id, username, email, role)

2. Actualizar método `login()` para retornar objeto completo

3. Actualizar `getUserProfile()` para usar endpoint correcto

4. Actualizar `AuthProvider` para guardar `userId`

### **PASO 3: Refactorizar ProductService**

1. Crear `ProductsResponse` para manejar paginación

2. Actualizar `getProducts()` para retornar `ProductsResponse`

3. Verificar que filtros funcionan correctamente

4. Actualizar pantallas que usan `getProducts()`

### **PASO 4: Actualizar Pantallas**

1. **LoginScreen**: Manejar nueva respuesta de login
2. **CatalogScreen**: Usar nueva estructura de productos
3. **UserProfileScreen**: Usar endpoint correcto

### **PASO 5: Testing Completo**

```
✅ Login → Ver user_id en logs
✅ Obtener perfil → Ver datos correctos
✅ Listar productos → Ver productos
✅ Buscar productos → Ver filtros funcionando
✅ Añadir al carrito → Ver item en carrito
✅ Crear orden → Ver orden creada
✅ Pagar → Ver pago exitoso
✅ Ver historial → Ver órdenes
✅ Ver detalle de orden → Ver items
✅ Escribir reseña → Ver reseña guardada
```

---

## 🎯 **Próximos Pasos Inmediatos**

1. **🔴 CRÍTICO**: Levantar el backend localmente
2. **🟡 ALTA**: Actualizar `baseUrl` en `api_service.dart`
3. **🟡 ALTA**: Refactorizar `AuthService.login()` y `getUserProfile()`
4. **🟢 MEDIA**: Actualizar `ProductService` para paginación
5. **🟢 MEDIA**: Actualizar pantallas según nuevos servicios
6. **🔵 BAJA**: Testing end-to-end completo

---

## 📞 **¿Necesitas Ayuda?**

Si necesitas ayuda para levantar el backend o tienes problemas:
1. Verifica que Python 3.8+ esté instalado
2. Verifica que tienes PostgreSQL o SQLite configurado
3. Revisa logs del servidor Django para errores
4. Contacta al propietario del repositorio backend (DiegoxdGarcia2)

---

**Fecha de análisis**: 10 de noviembre de 2025
**Estado**: ⚠️ **Backend NO disponible** - Requiere ser levantado antes de continuar
