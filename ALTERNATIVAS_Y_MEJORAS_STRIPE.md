# 💡 Alternativas y Mejoras Propuestas - Pasarela de Pago

## 🎯 Propuestas de Mejora Adicionales

### 1. 📱 Deep Linking para Retorno Automático

**Problema actual:** Usuario completa pago en navegador → debe volver manualmente a la app

**Solución propuesta:** Implementar Deep Links/App Links

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="smartsales365"
        android:host="payment" />
    <data 
        android:scheme="https"
        android:host="smartsales365.app"
        android:pathPrefix="/payment" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>smartsales365</string>
        </array>
    </dict>
</array>
```

#### Flutter (`lib/main.dart`):
```dart
import 'package:uni_links/uni_links.dart';

void initDeepLinks() {
  linkStream.listen((String? link) {
    if (link != null && link.contains('payment/success')) {
      // Navegar a pantalla de confirmación
      navigatorKey.currentState?.pushNamed('/checkout-confirmation');
    }
  });
}
```

#### Backend (Stripe success_url):
```python
# orders/views.py - CreateCheckoutSessionView
checkout_session = stripe.checkout.Session.create(
    success_url='smartsales365://payment/success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url='smartsales365://payment/cancel?session_id={CHECKOUT_SESSION_ID}',
    # ...
)
```

**Beneficios:**
- ✅ Usuario vuelve automáticamente a la app tras pagar
- ✅ UX fluida sin intervención manual
- ✅ Reduce confusión del usuario

---

### 2. 🎨 Stripe Payment Sheet (Nativo)

**Alternativa:** Usar `stripe_native_payment` en lugar de navegador web

```yaml
# pubspec.yaml
dependencies:
  stripe_native_payment: ^1.0.0
```

```dart
// lib/services/stripe_service.dart
import 'package:stripe_native_payment/stripe_native_payment.dart';

Future<void> openStripePaymentSheet(String clientSecret) async {
  await StripeNativePayment.presentPaymentSheet(
    clientSecret: clientSecret,
    options: PaymentSheetOptions(
      merchantDisplayName: 'SmartSales365',
      appearance: PaymentSheetAppearance(
        primaryButton: PaymentSheetPrimaryButtonAppearance(
          colors: PaymentSheetPrimaryButtonColors(
            light: '#28a745',
            dark: '#28a745',
          ),
        ),
      ),
    ),
  );
}
```

**Backend cambios:**
```python
# orders/views.py - CreateCheckoutSessionView
# En lugar de checkout.Session, usar PaymentIntent
payment_intent = stripe.PaymentIntent.create(
    amount=int(order.total_price * 100),
    currency='usd',
    metadata={'order_id': order.id},
)

return Response({
    'client_secret': payment_intent.client_secret,
    'publishable_key': settings.STRIPE_PUBLISHABLE_KEY,
})
```

**Ventajas:**
- ✅ UX nativa (no sale de la app)
- ✅ Soporte completo de 3D Secure
- ✅ Guarda métodos de pago para compras futuras
- ✅ Compatible con Apple Pay y Google Pay

**Desventajas:**
- ⚠️ Requiere cambios en backend (PaymentIntent en lugar de Checkout Session)
- ⚠️ Más complejo de implementar

---

### 3. 🔄 Retry Inteligente con Exponential Backoff

**Problema actual:** Si falla la creación de sesión Stripe, usuario debe reintentar manualmente

**Solución propuesta:**

```dart
// lib/services/order_service.dart
Future<String> createStripeCheckoutSessionWithRetry({
  required String token,
  required int orderId,
  int maxRetries = 3,
}) async {
  int attempt = 0;
  Duration delay = const Duration(seconds: 2);

  while (attempt < maxRetries) {
    try {
      attempt++;
      print('🔄 Intento $attempt de $maxRetries...');
      
      return await createStripeCheckoutSession(
        token: token,
        orderId: orderId,
      );
    } on SocketException catch (e) {
      // Sin internet: no reintentar automáticamente
      rethrow;
    } on TimeoutException catch (e) {
      if (attempt == maxRetries) rethrow;
      
      print('⏱️ Timeout. Reintentando en ${delay.inSeconds}s...');
      await Future.delayed(delay);
      
      // Exponential backoff: 2s → 4s → 8s
      delay = delay * 2;
    } catch (e) {
      // Otros errores: no reintentar
      rethrow;
    }
  }
  
  throw Exception('Falló tras $maxRetries intentos');
}
```

**Beneficios:**
- ✅ Resiliente ante fallos temporales del backend
- ✅ No molesta al usuario con reintentos en caso de sin internet
- ✅ Exponential backoff evita sobrecargar el servidor

---

### 4. 💾 Caché de Sesiones Stripe

**Problema actual:** Si usuario cierra la app tras crear sesión, pierde la URL de pago

**Solución propuesta:**

```dart
// lib/services/cache_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PaymentCacheService {
  static const String _keyOrderId = 'last_order_id';
  static const String _keyCheckoutUrl = 'last_checkout_url';
  static const String _keyTimestamp = 'last_checkout_timestamp';
  
  Future<void> saveCheckoutSession({
    required int orderId,
    required String checkoutUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyOrderId, orderId);
    await prefs.setString(_keyCheckoutUrl, checkoutUrl);
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }
  
  Future<Map<String, dynamic>?> getLastCheckoutSession() async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = prefs.getInt(_keyOrderId);
    final checkoutUrl = prefs.getString(_keyCheckoutUrl);
    final timestamp = prefs.getInt(_keyTimestamp);
    
    if (orderId == null || checkoutUrl == null || timestamp == null) {
      return null;
    }
    
    // Expirar sesiones de más de 24 horas
    final sessionAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (sessionAge > 24 * 60 * 60 * 1000) {
      await clearCheckoutSession();
      return null;
    }
    
    return {
      'order_id': orderId,
      'checkout_url': checkoutUrl,
      'timestamp': timestamp,
    };
  }
  
  Future<void> clearCheckoutSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOrderId);
    await prefs.remove(_keyCheckoutUrl);
    await prefs.remove(_keyTimestamp);
  }
}
```

**Uso:**
```dart
// Tras crear sesión exitosa
await PaymentCacheService().saveCheckoutSession(
  orderId: order.id,
  checkoutUrl: url,
);

// Al abrir la app, verificar si hay sesión pendiente
final cachedSession = await PaymentCacheService().getLastCheckoutSession();
if (cachedSession != null) {
  // Mostrar diálogo: "Tienes un pago pendiente. ¿Continuar?"
}
```

**Beneficios:**
- ✅ Usuario puede continuar pago incluso tras cerrar la app
- ✅ Reduce abandono de carritos
- ✅ Sesiones se limpian automáticamente tras 24h

---

### 5. 🔔 Notificaciones Push al Completar Pago

**Implementación:**

```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static Future<void> initializeNotifications() async {
    final messaging = FirebaseMessaging.instance;
    
    // Solicitar permisos
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Obtener token FCM
    final token = await messaging.getToken();
    print('📱 FCM Token: $token');
    
    // Enviar token al backend
    // await authService.updateFcmToken(token);
  }
  
  static void listenToNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Notificación recibida: ${message.notification?.title}');
      
      // Mostrar notificación local
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
        );
      }
    });
  }
}
```

**Backend:**
```python
# orders/views.py - StripeWebhookView
from firebase_admin import messaging

def send_payment_confirmation_notification(user, order):
    message = messaging.Message(
        notification=messaging.Notification(
            title='¡Pago Exitoso!',
            body=f'Tu orden #{order.id} de ${order.total_price} ha sido confirmada.',
        ),
        data={
            'order_id': str(order.id),
            'type': 'payment_success',
        },
        token=user.fcm_token,
    )
    
    response = messaging.send(message)
    print(f'📤 Notificación enviada: {response}')
```

**Beneficios:**
- ✅ Usuario es notificado inmediatamente (no espera polling)
- ✅ Funciona incluso con app en background
- ✅ Mejora percepción de velocidad

---

### 6. 📊 Analytics y Tracking

**Implementación:**

```dart
// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> logCheckoutStarted({
    required double totalPrice,
    required int itemCount,
  }) async {
    await _analytics.logBeginCheckout(
      value: totalPrice,
      currency: 'USD',
      items: [
        AnalyticsEventItem(
          itemName: 'cart',
          quantity: itemCount,
        ),
      ],
    );
  }
  
  static Future<void> logPaymentSuccess({
    required int orderId,
    required double totalPrice,
  }) async {
    await _analytics.logPurchase(
      value: totalPrice,
      currency: 'USD',
      transactionId: orderId.toString(),
    );
  }
  
  static Future<void> logPaymentFailed({
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'payment_failed',
      parameters: {
        'reason': reason,
      },
    );
  }
}
```

**Uso:**
```dart
// En payment_provider.dart
await AnalyticsService.logCheckoutStarted(
  totalPrice: cart.totalPrice,
  itemCount: cart.itemsCount,
);

// En checkout_confirmation_screen.dart
if (order.status == 'PAGADO') {
  await AnalyticsService.logPaymentSuccess(
    orderId: order.id,
    totalPrice: order.totalPrice,
  );
}
```

**Beneficios:**
- ✅ Métricas de conversión
- ✅ Identificar puntos de abandono
- ✅ Optimizar funnel de compra

---

### 7. 🎨 Stripe Payment Element (Web)

**Para versión web de la app:**

```dart
// lib/services/stripe_web_service.dart
import 'dart:html' as html;
import 'dart:js' as js;

class StripeWebService {
  static void loadStripeJs() {
    final script = html.ScriptElement()
      ..src = 'https://js.stripe.com/v3/'
      ..async = true;
    html.document.head!.append(script);
  }
  
  static Future<void> mountPaymentElement({
    required String clientSecret,
    required String publishableKey,
  }) async {
    js.context.callMethod('eval', ['''
      const stripe = Stripe('$publishableKey');
      const elements = stripe.elements({ clientSecret: '$clientSecret' });
      const paymentElement = elements.create('payment');
      paymentElement.mount('#payment-element');
      
      document.getElementById('submit-btn').addEventListener('click', async () => {
        const {error} = await stripe.confirmPayment({
          elements,
          confirmParams: {
            return_url: 'https://smartsales365.app/payment/success',
          },
        });
        
        if (error) {
          console.error(error.message);
        }
      });
    ''']);
  }
}
```

---

## 🔒 Mejoras de Seguridad

### 1. Certificado SSL Pinning

```dart
// pubspec.yaml
dependencies:
  dio: ^5.0.0

// lib/services/secure_http_service.dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class SecureHttpService {
  static Dio createSecureDio() {
    final dio = Dio();
    
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        // Validar certificado específico del backend
        return cert.sha1.toString() == 'EXPECTED_SHA1_HASH';
      };
      return client;
    };
    
    return dio;
  }
}
```

**Beneficios:**
- ✅ Previene ataques Man-in-the-Middle
- ✅ Mayor seguridad en redes públicas

---

### 2. Biometría para Confirmar Pago

```dart
// pubspec.yaml
dependencies:
  local_auth: ^2.1.0

// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  
  static Future<bool> authenticateForPayment() async {
    try {
      final canAuth = await _auth.canCheckBiometrics;
      if (!canAuth) return true; // Skip si no disponible
      
      return await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para proceder al pago',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('❌ Error biométrico: $e');
      return true; // Permitir continuar en caso de error
    }
  }
}
```

**Uso:**
```dart
// En cart_screen.dart - _processCheckout()
final authenticated = await BiometricService.authenticateForPayment();
if (!authenticated) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Autenticación requerida para continuar'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
```

---

## 📈 Mejoras de Performance

### 1. Precarga de Sesión Stripe

```dart
// Crear sesión Stripe en segundo plano mientras usuario ingresa dirección
Future<void> _processCheckout() async {
  // 1. Mostrar diálogo de dirección
  final shippingInfo = await showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _ShippingInfoDialog(),
  );
  
  // 2. Mientras tanto, crear orden y sesión en paralelo
  final results = await Future.wait([
    _createOrder(shippingInfo),
    _createStripeSession(), // ← Se ejecuta en paralelo
  ]);
  
  // 3. Ambos completados → abrir Stripe inmediatamente
}
```

---

### 2. Caché de Productos

```dart
// lib/services/cache_service.dart
import 'package:hive/hive.dart';

class ProductCacheService {
  static Future<void> cacheProducts(List<Product> products) async {
    final box = await Hive.openBox('products');
    await box.put('cached_products', products);
    await box.put('cached_at', DateTime.now().toIso8601String());
  }
  
  static Future<List<Product>?> getCachedProducts() async {
    final box = await Hive.openBox('products');
    final cachedAt = box.get('cached_at');
    
    if (cachedAt == null) return null;
    
    // Expirar caché de más de 1 hora
    final cacheAge = DateTime.now().difference(DateTime.parse(cachedAt));
    if (cacheAge.inHours > 1) return null;
    
    return box.get('cached_products');
  }
}
```

---

## 🎯 Recomendación Final

### Implementación Prioritaria

1. **📱 Deep Linking** (Alta prioridad)
   - Mejora dramáticamente UX
   - Relativamente fácil de implementar
   
2. **🔄 Retry Inteligente** (Media prioridad)
   - Reduce fallos transitorios
   - Aumenta tasa de conversión
   
3. **💾 Caché de Sesiones** (Media prioridad)
   - Reduce abandono de carritos
   - Fácil de implementar

4. **🎨 Stripe Payment Sheet** (Baja prioridad)
   - Mejor UX pero requiere refactor backend
   - Considerar para v2.0

5. **🔔 Notificaciones Push** (Opcional)
   - Solo si ya tienen Firebase configurado
   - Mejora percepción de velocidad

---

## ✅ Checklist de Implementación

- [ ] Deep Linking configurado (Android + iOS)
- [ ] Retry con exponential backoff
- [ ] Caché de sesiones Stripe con SharedPreferences
- [ ] Biometría para confirmar pago
- [ ] Analytics de funnel de compra
- [ ] SSL Pinning para seguridad
- [ ] Notificaciones push al completar pago
- [ ] Precarga de sesión Stripe
- [ ] Caché de productos con Hive

---

## 📞 Soporte

Para cualquier duda o problema con estas implementaciones, consultar:
- Documentación de Stripe: https://stripe.com/docs
- Flutter Deep Linking: https://docs.flutter.dev/ui/navigation/deep-linking
- Firebase Cloud Messaging: https://firebase.google.com/docs/cloud-messaging
