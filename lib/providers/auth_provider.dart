// lib/providers/auth_provider.dart

// ignore_for_file: unnecessary_null_comparison, avoid_print, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartsales365/services/auth_service.dart';
import 'package:smartsales365/models/user_model.dart';
import 'package:smartsales365/models/login_response_model.dart';
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
  String? _accessToken;
  String? _refreshToken;
  int? _userId; // ID del usuario guardado desde login
  String? _username;
  String? _email;
  String? _role; // Rol del usuario: "ADMINISTRADOR" o "CLIENTE"
  UserProfile? _userProfile;
  String? _errorMessage;

  // Getters públicos
  AuthStatus get status => _status;
  String? get token => _accessToken; // Mantener compatibilidad
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  int? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;

  // Verifica si el usuario es administrador según el rol del backend
  bool get isAdmin => _role == 'ADMINISTRADOR';

  // Verifica si el usuario es cliente
  bool get isClient => _role == 'CLIENTE';

  AuthProvider() {
    _initAuth();
  }

  /// Inicializa el provider, intentando cargar el token desde el storage
  Future<void> _initAuth() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final String? storedAccessToken = await _storage.read(key: 'accessToken');
    final String? storedRefreshToken = await _storage.read(key: 'refreshToken');
    final String? storedUserId = await _storage.read(key: 'userId');
    final String? storedUsername = await _storage.read(key: 'username');
    final String? storedEmail = await _storage.read(key: 'email');
    final String? storedRole = await _storage.read(key: 'role');

    if (storedAccessToken != null && storedUserId != null) {
      _accessToken = storedAccessToken;
      _refreshToken = storedRefreshToken;
      _userId = int.tryParse(storedUserId);
      _username = storedUsername;
      _email = storedEmail;
      _role = storedRole;

      // Intentar cargar el perfil completo
      final String? storedProfile = await _storage.read(key: 'userProfile');
      if (storedProfile != null) {
        try {
          _userProfile = UserProfile.fromJson(jsonDecode(storedProfile));
          _status = AuthStatus.authenticated;
          notifyListeners();
          return;
        } catch (e) {
          print('⚠️ Error al parsear perfil guardado: $e');
        }
      }

      // Si no hay perfil guardado o falló el parseo, intentar obtenerlo
      if (_userId != null) {
        await _fetchProfile(storedAccessToken, _userId!);
      } else {
        _status =
            AuthStatus.authenticated; // Autenticado aunque sin perfil completo
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Busca el perfil del usuario usando un token y userId
  Future<void> _fetchProfile(String token, int userId) async {
    try {
      print('📥 Obteniendo perfil del usuario ID: $userId');
      final user = await _authService.getUserProfile(token, userId);
      _userProfile = user;
      _status = AuthStatus.authenticated;

      // Guarda el perfil de usuario en el storage
      await _storage.write(
        key: 'userProfile',
        value: jsonEncode(user.toJson()),
      );
      print('✅ Perfil guardado en storage');
    } catch (e) {
      print('❌ Error al obtener perfil: $e');
      // No cerramos sesión, solo no tenemos el perfil completo
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  /// Iniciar Sesión
  /// Retorna LoginResponse con access token, refresh token y datos del usuario
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔐 Intentando login como: $username');
      final loginResponse = await _authService.login(username, password);

      // Guardar tokens
      _accessToken = loginResponse.accessToken;
      _refreshToken = loginResponse.refreshToken;

      // Guardar datos del usuario
      _userId = loginResponse.user.id;
      _username = loginResponse.user.username;
      _email = loginResponse.user.email;
      _role = loginResponse.user.role;

      print('✅ Login exitoso');
      print('👤 Usuario: $_username (ID: $_userId)');
      print('🎭 Rol: $_role');
      print('📧 Email: $_email');

      // Guardar todo en secure storage
      await _storage.write(key: 'accessToken', value: _accessToken);
      await _storage.write(key: 'refreshToken', value: _refreshToken);
      await _storage.write(key: 'userId', value: _userId.toString());
      await _storage.write(key: 'username', value: _username);
      await _storage.write(key: 'email', value: _email);
      if (_role != null) {
        await _storage.write(key: 'role', value: _role);
      }

      // Obtener perfil completo del usuario
      await _fetchProfile(_accessToken!, _userId!);

      return true;
    } catch (e) {
      print('❌ Error en login: $e');
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
    print('👋 Cerrando sesión...');
    _status = AuthStatus.unauthenticated;
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _username = null;
    _email = null;
    _role = null;
    _userProfile = null;
    _errorMessage = null;

    // Limpia el storage
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'userProfile');

    print('✅ Sesión cerrada');
    notifyListeners();
  }

  /// Refrescar el access token usando el refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      print('❌ No hay refresh token disponible');
      await logout();
      return false;
    }

    try {
      print('🔄 Refrescando access token...');
      final newAccessToken = await _authService.refreshAccessToken(
        _refreshToken!,
      );
      _accessToken = newAccessToken;

      // Guardar el nuevo access token
      await _storage.write(key: 'accessToken', value: newAccessToken);

      print('✅ Access token refrescado');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error al refrescar token: $e');
      await logout(); // Si falla el refresh, cerrar sesión
      return false;
    }
  }
}
