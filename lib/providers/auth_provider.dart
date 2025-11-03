import 'package:flutter/material.dart';
// Asegúrate de que la ruta a tu servicio sea correcta
import 'package:smartsales365/services/auth_service.dart';

// 1. CORRECCIÓN DEL ENUM: Añadimos 'loading'
enum AuthStatus {
  uninitialized, // Estado inicial
  authenticated, // Logueado
  unauthenticated, // No logueado
  loading, // Cargando (para login/registro)
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _accessToken;
  String? _errorMessage;

  // Getters públicos
  AuthStatus get status => _status;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    tryAutoLogin();
  }

  // 1. Intento de Auto-Login
  Future<void> tryAutoLogin() async {
    _status = AuthStatus.uninitialized; // Estado de carga inicial
    notifyListeners();

    bool success = await _authService.refreshToken();

    if (success) {
      _accessToken = await _authService.getAccessToken();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // 2. Iniciar Sesión Manual
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading; // Usamos 'loading'
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(username, password);

    if (result['success'] == true) {
      _accessToken = result['access'];
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _accessToken = null;
      _status = AuthStatus.unauthenticated; // Vuelve a no autenticado
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // 3. Cerrar Sesión
  Future<void> logout() async {
    await _authService.logout();
    _accessToken = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // 4. CORRECCIÓN: FUNCIÓN 'register' AÑADIDA
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    _status = AuthStatus.loading; // Usamos 'loading'
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
      firstName: firstName, // Opcional
      lastName: lastName, // Opcional
    );

    if (result['success'] == true) {
      // Si el registro es exitoso, volvemos a 'unauthenticated'
      // para que el usuario pueda hacer login.
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } else {
      // Falla el registro
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
