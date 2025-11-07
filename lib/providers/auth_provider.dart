// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
// Importa tu propio auth_service.dart, que ya es muy avanzado
import 'package:smartsales365/services/auth_service.dart';

// 1. DEFINIMOS EL ENUM 'AuthStatus' AQUÍ
// (Esto arregla "Undefined name 'AuthStatus'")
enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

// 2. USAMOS 'with ChangeNotifier' (como ya corregiste)
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // 3. DEFINIMOS LAS PROPIEDADES QUE TUS PANTALLAS NECESITAN
  AuthStatus _status = AuthStatus.uninitialized;
  String? _accessToken;
  String? _errorMessage;

  // 4. CREAMOS LOS 'GETTERS' PÚBLICOS
  // (Esto arregla "The getter 'status' isn't defined")
  AuthStatus get status => _status;

  // (Esto arregla "The getter 'errorMessage' isn't defined")
  String? get errorMessage => _errorMessage;

  String? get accessToken => _accessToken;

  // Constructor
  AuthProvider() {
    tryAutoLogin();
  }

  // --- MÉTODOS ---

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.uninitialized;
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

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
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
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _accessToken = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // 5. DEFINIMOS EL MÉTODO 'register'
  // (Esto arregla "The method 'register' isn't defined")
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    if (result['success'] == true) {
      // Éxito, pero el usuario debe iniciar sesión
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } else {
      // Falló el registro
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
