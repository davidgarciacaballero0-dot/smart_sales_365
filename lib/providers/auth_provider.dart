// lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smartsales365/services/api_service.dart';
import 'package:smartsales365/models/user_model.dart' as user_model;

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  user_model.UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  // --- GETTERS PÚBLICOS ---

  // El token de acceso
  String? get token => _token;

  // El perfil del usuario (contiene username, email, rol, etc.)
  user_model.UserProfile? get userProfile => _userProfile;

  // Estado de autenticación
  bool get isAuthenticated => _token != null;

  // Estado de administrador
  bool get isAdmin {
    return _userProfile?.role.name.toLowerCase() == 'admin';
  }

  // Estado de carga
  bool get isLoading => _isLoading;

  // Mensaje de error
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _setLoading(true);
    _token = await _storage.read(key: 'token');
    _refreshToken = await _storage.read(key: 'refreshToken');

    if (_token != null) {
      try {
        await _fetchUserProfile();
      } catch (e) {
        // El token pudo haber expirado, intentar refrescar
        try {
          await _refreshTokenRequest();
        } catch (refreshError) {
          // Si el refresh falla, desloguear
          await logout();
        }
      }
    }
    _setLoading(false);
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
    _setLoading(true);
    _clearError();

    try {
      final tokens = await _authService.login(username, password);
      _token = tokens['access'];
      _refreshToken = tokens['refresh'];

      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'refreshToken', value: _refreshToken);

      await _fetchUserProfile(); // Cargar perfil después de login
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.register(username, email, password);
      // Después de registrar, hacer login automáticamente
      bool loggedIn = await login(username, password);
      _setLoading(false);
      return loggedIn;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _userProfile = null;

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
      // A veces el refresh no devuelve un nuevo refresh token,
      // así que solo lo actualizamos si existe
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

// --- CLASE DE SERVICIO DE AUTH ---
// (Normalmente estaría en auth_service.dart, pero está aquí en tu repo)

class AuthService {
  final String _baseUrl = ApiService.baseUrl;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/token/'),
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
      Uri.parse('$_baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  Future<user_model.UserProfile> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // decodificar bodyBytes para UTF-8
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return user_model.UserProfile.fromJson(body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<void> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      try {
        // Intentar dar un error más específico
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
