// lib/providers/auth_provider.dart

// ignore_for_file: unused_import

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smartsales365/services/api_service.dart';
// CORRECCIÓN (Errores 1, 2, 4, 6): Importar el modelo de usuario
import 'package:smartsales365/models/user_model.dart' as user_model;

// ENUM para AuthStatus (usado en login_screen, main.dart, etc.)
enum AuthStatus {
  unknown,
  unauthenticated,
  authenticated,
  loading,
  uninitialized,
}

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  // CORRECCIÓN (Errores 1, 2, 4, 6): Usar la clase 'User' en lugar de 'UserProfile'
  user_model.User? _userProfile;

  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  // --- GETTERS PÚBLICOS ---

  String? get token => _token;
  // CORRECCIÓN (Errores 1, 2, 4, 6): Usar la clase 'User'
  user_model.User? get userProfile => _userProfile;
  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  bool get isAdmin {
    // Asegurarse de que userProfile y role no sean nulos
    return _userProfile?.role.name.toLowerCase() == 'admin';
  }

  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _token = await _storage.read(key: 'token');
    _refreshToken = await _storage.read(key: 'refreshToken');

    if (_token != null) {
      try {
        await _fetchUserProfile();
        _status = AuthStatus.authenticated;
      } catch (e) {
        // El token pudo haber expirado, intentar refrescar
        try {
          await _refreshTokenRequest();
          _status = AuthStatus.authenticated;
        } catch (refreshError) {
          // Si el refresh falla, desloguear
          await logout(); // logout pondrá el estado en unauthenticated
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _fetchUserProfile() async {
    if (_token == null) return;

    try {
      final profile = await _authService.getUserProfile(_token!);
      _userProfile = profile;
    } catch (e) {
      _userProfile = null;
      throw Exception('Failed to fetch profile: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _clearError();
    notifyListeners();

    try {
      final tokens = await _authService.login(username, password);
      _token = tokens['access'];
      _refreshToken = tokens['refresh'];

      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'refreshToken', value: _refreshToken);

      await _fetchUserProfile(); // Cargar perfil después de login
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _status = AuthStatus.loading;
    _clearError();
    notifyListeners();

    try {
      await _authService.register(username, email, password);
      // Después de registrar, hacer login automáticamente
      bool loggedIn = await login(username, password);
      // El estado ya se actualiza dentro de login()
      return loggedIn;
    } catch (e) {
      _setError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _userProfile = null;
    _status = AuthStatus.unauthenticated;

    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');

    notifyListeners();
  }

  Future<void> _refreshTokenRequest() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final newTokens = await _authService.refreshToken(_refreshToken!);
      _token = newTokens['access'];
      if (newTokens.containsKey('refresh')) {
        _refreshToken = newTokens['refresh'];
        await _storage.write(key: 'refreshToken', value: _refreshToken);
      }
      await _storage.write(key: 'token', value: _token);

      await _fetchUserProfile(); // Cargar perfil con el nuevo token
    } catch (e) {
      // Si el refresh falla, desloguear al usuario
      await logout();
      throw Exception('Session expired. Please log in again.');
    }
  }

  void _setError(String message) {
    _errorMessage = message;
  }

  void _clearError() {
    _errorMessage = null;
  }
}

// --- AuthService ---
// (Esta clase está en tu auth_provider.dart, así que la mantenemos aquí)

class AuthService {
  // CORRECCIÓN (Error 3): Usar 'baseUrl' (constante global) en lugar de 'ApiService.baseUrl'
  final String _baseUrl =
      'https://smartsales-backend-891739940726.us-central1.run.app/api';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/login/'), // Endpoint de login
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falló al iniciar sesión. Verifica tus credenciales.');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/token/refresh/'), // Endpoint de refresh
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  // CORRECCIÓN (Errores 1, 2, 4, 6): Devolver un 'user_model.User'
  Future<user_model.User> getUserProfile(String token) async {
    // CORRECCIÓN (Error 5): Usar 'Uri.parse' en lugar de 'Uri.para'
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/'), // Endpoint de perfil
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      // CORRECCIÓN (Errores 1, 2, 4, 6): Usar 'User.fromJson'
      return user_model.User.fromJson(body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<void> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register/'), // Endpoint de registro
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      try {
        final errorBody = jsonDecode(response.body);
        String error = errorBody.toString();
        if (errorBody.containsKey('username')) {
          error = errorBody['username'][0];
        } else if (errorBody.containsKey('email')) {
          error = errorBody['email'][0];
        }
        throw Exception('Error de registro: $error');
      } catch (e) {
        throw Exception('Error al registrar usuario: ${response.statusCode}');
      }
    }
  }
}
