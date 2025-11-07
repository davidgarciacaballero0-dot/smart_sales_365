// lib/providers/auth_provider.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smartsales365/services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _accessToken;
  String? _errorMessage;

  // --- ¡NUEVO ESTADO PARA EL ROL! ---
  String? _userRole;

  AuthStatus get status => _status;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;

  // --- ¡NUEVO GETTER! ---
  /// Revisa si el usuario actual es un administrador
  bool get isAdmin => _userRole == 'admin';

  AuthProvider() {
    tryAutoLogin();
  }

  /// Método auxiliar para obtener y guardar el perfil del usuario
  Future<void> _fetchAndSetUserProfile(String token) async {
    try {
      final result = await _authService.getUserProfile(token);
      if (result['success'] == true && result['user'] != null) {
        // Guardamos el rol (ej. 'admin' o 'client')
        _userRole = result['user']['role'];
      }
    } catch (e) {
      print('Error al obtener perfil de usuario: $e');
    }
  }

  Future<void> tryAutoLogin() async {
    _status = AuthStatus.uninitialized;
    notifyListeners();

    bool success = await _authService.refreshToken();
    if (success) {
      _accessToken = await _authService.getAccessToken();

      // --- ¡ACTUALIZACIÓN! ---
      // Si tenemos token, también obtenemos el perfil/rol
      if (_accessToken != null) {
        await _fetchAndSetUserProfile(_accessToken!);
      }

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

      // --- ¡ACTUALIZACIÓN! ---
      // Si el login fue exitoso, obtenemos el perfil/rol
      if (_accessToken != null) {
        await _fetchAndSetUserProfile(_accessToken!);
      }

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
    _userRole = null; // Limpiamos el rol al salir
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // (El método de registro no cambia)
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
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
