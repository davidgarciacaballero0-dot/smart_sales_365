// lib/providers/auth_provider.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smart_sales_365/models/user_model.dart';
import 'package:smart_sales_365/services/auth_service.dart';

// Definimos los posibles estados de autenticación
enum AuthStatus {
  uninitialized, // Estado inicial, al abrir la app
  authenticated, // Logueado exitosamente
  unauthenticated, // No logueado (o sesión cerrada)
  authenticating, // Cargando (presionó "Ingresar")
  registering, // Cargando (presionó "Registrar")
}

class AuthProvider with ChangeNotifier {
  // Instancia privada de nuestro servicio de API
  final AuthService _authService = AuthService();

  // --- Variables de Estado Privadas ---
  AuthStatus _authStatus = AuthStatus.uninitialized;
  AuthUser? _user;
  String _errorMessage = '';

  // --- Getters Públicos ---
  // La UI leerá estos valores para saber qué mostrar
  AuthStatus get authStatus => _authStatus;
  AuthUser? get user => _user;
  String get errorMessage => _errorMessage;

  // Getters de conveniencia
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  bool get isLoading =>
      _authStatus == AuthStatus.authenticating ||
      _authStatus == AuthStatus.registering ||
      _authStatus == AuthStatus.uninitialized;

  // --- Constructor ---
  // Cuando se crea el AuthProvider (al inicio de la app),
  // inmediatamente revisa si ya existe una sesión guardada.
  AuthProvider() {
    _checkLoginStatus();
  }

  // Verifica la sesión guardada en SharedPreferences
  Future<void> _checkLoginStatus() async {
    // Usamos el método que creamos en AuthService
    final AuthUser? loggedInUser = await _authService.getInitialAuthStatus();

    if (loggedInUser != null) {
      _user = loggedInUser;
      _authStatus = AuthStatus.authenticated;
    } else {
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
    }
    // Notifica a todos los widgets que están "escuchando"
    notifyListeners();
  }

  // --- Función de Login ---
  Future<bool> login(String usernameOrEmail, String password) async {
    _authStatus = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final AuthUser loggedInUser = await _authService.login(
        usernameOrEmail,
        password,
      );
      _user = loggedInUser;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // --- Función de Registro ---
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    _authStatus = AuthStatus.registering;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Intentar registrar el usuario
      final bool registerSuccess = await _authService.register(
        username: username,
        email: email,
        password: password,
        password2: password2,
      );

      if (registerSuccess) {
        // 2. Si el registro es exitoso, hacer login automáticamente
        // La pantalla mostrará "Cargando" (authenticating)
        print('Registro exitoso, intentando login automático...');
        return await login(
          username,
          password,
        ); // Reutilizamos la función de login
      } else {
        // Esto teóricamente no debería pasar si el servicio lanza excepciones
        _authStatus = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // --- Función de Logout ---
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
