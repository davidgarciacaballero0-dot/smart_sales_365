// lib/providers/auth_provider.dart

// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartsales365/services/auth_service.dart';
import 'package:smartsales365/models/user_model.dart';
import 'dart:async';
import 'dart:convert';

// Enum para el estado de autenticación
enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  UserProfile? _userProfile;
  String? _errorMessage;

  // Getters públicos
  AuthStatus get status => _status;
  String? get token => _token;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;

  bool get isAdmin {
    // Verifica si 'role' no es nulo y si 'name' es 'Admin'
    return _userProfile?.role != null && _userProfile?.role.name == 'Admin';
  }

  AuthProvider() {
    _initAuth();
  }

  /// Inicializa el provider, intentando cargar el token desde el storage
  Future<void> _initAuth() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final String? storedToken = await _storage.read(key: 'authToken');

    if (storedToken != null) {
      final String? storedUser = await _storage.read(key: 'userProfile');
      _token = storedToken;

      if (storedUser != null) {
        try {
          _userProfile = UserProfile.fromJson(jsonDecode(storedUser));
          _status = AuthStatus.authenticated;
        } catch (e) {
          // Si el perfil de usuario está corrupto, lo tratamos como no autenticado
          await logout();
          return;
        }
      } else {
        // Si hay token pero no perfil, intenta obtener el perfil
        await _fetchProfile(storedToken);
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Busca el perfil del usuario usando un token
  Future<void> _fetchProfile(String token) async {
    try {
      final user = await _authService.getUserProfile(token);
      _userProfile = user;
      _token = token;
      _status = AuthStatus.authenticated;

      // Guarda el perfil de usuario en el storage
      await _storage.write(
        key: 'userProfile',
        value: jsonEncode(user.toJson()),
      );
    } catch (e) {
      // Si el token es inválido, cerramos sesión
      await logout();
    }
    notifyListeners();
  }

  /// Iniciar Sesión
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(username, password);
      if (token != null) {
        await _storage.write(key: 'authToken', value: token);
        await _fetchProfile(token); // Busca el perfil después de login
        return true;
      } else {
        _errorMessage = 'Usuario o contraseña incorrectos.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Registrar un nuevo usuario
  // CORRECCIÓN: Esta es la definición correcta que usa parámetros nombrados
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {'username': username, 'email': email, 'password': password};

      await _authService.register(data);

      // Después de registrar, intenta hacer login automáticamente
      return await login(username, password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar Sesión
  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _token = null;
    _userProfile = null;
    _errorMessage = null;

    // Limpia el storage
    await _storage.delete(key: 'authToken');
    await _storage.delete(key: 'userProfile');

    notifyListeners();
  }
}
