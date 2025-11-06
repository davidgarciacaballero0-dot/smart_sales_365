// lib/providers/auth_provider.dart

// 'foundation.dart' nos da acceso a 'ChangeNotifier'
import 'package:flutter/foundation.dart';
import 'package:smartsales365/services/api_service.dart';

// 'with ChangeNotifier' es lo que le da a esta clase
// el poder de "notificar" a los widgets cuando algo cambia.
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- ESTADO INTERNO DE LA APP ---

  // Guardamos el estado de autenticación.
  // Usamos 'bool?' (booleano nulable) para tener 3 estados:
  // null = 'desconocido' (la app acaba de iniciar, aún no hemos revisado)
  // true = 'autenticado'
  // false = 'anónimo' (no está logueado)
  bool? _isAuthenticated;

  // --- GETTERS (Forma pública de leer el estado) ---

  /// 'true' si el usuario está logueado, 'false' en cualquier otro caso.
  bool get isAuthenticated => _isAuthenticated == true;

  /// 'true' si ya terminamos de revisar el token al inicio.
  /// Lo usamos para mostrar una pantalla de carga (Splash Screen) al inicio.
  bool get isAuthStatusKnown => _isAuthenticated != null;

  // --- CONSTRUCTOR ---

  /// El Constructor se ejecuta tan pronto se crea el AuthProvider.
  AuthProvider() {
    // Inmediatamente, mandamos a revisar si ya teníamos un token guardado
    _checkTokenOnStartup();
  }

  // --- MÉTODOS PRIVADOS ---

  /// Revisa el 'FlutterSecureStorage' al iniciar la app.
  void _checkTokenOnStartup() async {
    final token = await _apiService.getToken();

    // Pequeña demora para que la transición sea suave (opcional)
    await Future.delayed(const Duration(milliseconds: 500));

    if (token != null) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }

    // ¡Aviso a todos los widgets que estén "escuchando"!
    // Les digo: "¡Ya sé el estado de autenticación, pueden redibujarse!"
    notifyListeners();
  }

  // --- ACCIONES (Métodos públicos llamados por la UI) ---

  /// Intenta iniciar sesión.
  /// Devuelve 'null' si fue exitoso.
  /// Devuelve un 'String' con el mensaje de error si falló.
  Future<String?> login(String email, String password) async {
    try {
      bool success = await _apiService.login(email, password);

      if (success) {
        _isAuthenticated = true;
        // Notificamos a los widgets que el estado cambió (de 'false' a 'true')
        notifyListeners();
        return null; // Éxito, no hay error
      } else {
        // Falló el login (email/pass incorrectos)
        return 'Email o contraseña incorrectos.';
      }
    } catch (e) {
      // Captura errores de conexión (ej. SocketException del ApiService)
      return e.toString().replaceAll('Exception: ', ''); // Devuelve el error
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    await _apiService.logout(); // Borra el token
    _isAuthenticated = false;
    notifyListeners(); // Notifica que el estado cambió (de 'true' a 'false')
  }
} // lib/providers/auth_provider.dart
// 'foundation.dart' nos da acceso a 'ChangeNotifier'

// 'with ChangeNotifier' es lo que le da a esta clase
// el poder de "notificar" a los widgets cuando algo cambia.
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- ESTADO INTERNO DE LA APP ---

  // Guardamos el estado de autenticación.
  // Usamos 'bool?' (booleano nulable) para tener 3 estados:
  // null = 'desconocido' (la app acaba de iniciar, aún no hemos revisado)
  // true = 'autenticado'
  // false = 'anónimo' (no está logueado)
  bool? _isAuthenticated;

  // --- GETTERS (Forma pública de leer el estado) ---

  /// 'true' si el usuario está logueado, 'false' en cualquier otro caso.
  bool get isAuthenticated => _isAuthenticated == true;

  /// 'true' si ya terminamos de revisar el token al inicio.
  /// Lo usamos para mostrar una pantalla de carga (Splash Screen) al inicio.
  bool get isAuthStatusKnown => _isAuthenticated != null;

  // --- CONSTRUCTOR ---

  /// El Constructor se ejecuta tan pronto se crea el AuthProvider.
  AuthProvider() {
    // Inmediatamente, mandamos a revisar si ya teníamos un token guardado
    _checkTokenOnStartup();
  }

  // --- MÉTODOS PRIVADOS ---

  /// Revisa el 'FlutterSecureStorage' al iniciar la app.
  void _checkTokenOnStartup() async {
    final token = await _apiService.getToken();

    // Pequeña demora para que la transición sea suave (opcional)
    await Future.delayed(const Duration(milliseconds: 500));

    if (token != null) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }

    // ¡Aviso a todos los widgets que estén "escuchando"!
    // Les digo: "¡Ya sé el estado de autenticación, pueden redibujarse!"
    notifyListeners();
  }

  // --- ACCIONES (Métodos públicos llamados por la UI) ---

  /// Intenta iniciar sesión.
  /// Devuelve 'null' si fue exitoso.
  /// Devuelve un 'String' con el mensaje de error si falló.
  Future<String?> login(String email, String password) async {
    try {
      bool success = await _apiService.login(email, password);

      if (success) {
        _isAuthenticated = true;
        // Notificamos a los widgets que el estado cambió (de 'false' a 'true')
        notifyListeners();
        return null; // Éxito, no hay error
      } else {
        // Falló el login (email/pass incorrectos)
        return 'Email o contraseña incorrectos.';
      }
    } catch (e) {
      // Captura errores de conexión (ej. SocketException del ApiService)
      return e.toString().replaceAll('Exception: ', ''); // Devuelve el error
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    await _apiService.logout(); // Borra el token
    _isAuthenticated = false;
    notifyListeners(); // Notifica que el estado cambió (de 'true' a 'false')
  }
}
