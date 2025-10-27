// lib/services/auth_service.dart
// ignore_for_file: avoid_print

import 'dart:convert'; // Para jsonEncode y jsonDecode
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart'; // Para leer el token
import 'package:shared_preferences/shared_preferences.dart'; // Para guardar tokens
import 'package:smart_sales_365/models/user_model.dart'; // Nuestro modelo

class AuthService {
  // --- URL Base de tu API ---
  // Esta debe ser la URL de tu backend desplegado en Render
  final String _baseUrl = 'https://smartsales-backend.onrender.com/api';
  // '[https://smartsales-backend.onrender.com/api](https://smartsales-backend.onrender.com/api)'; // <-- Verifica esta URL
  // --- Claves para SharedPreferences ---
  final String _accessTokenKey = 'access_token';
  final String _refreshTokenKey = 'refresh_token';
  final String _userDataKey =
      'user_data'; // Para guardar los datos del AuthUser

  // --- Método de Login (CU-21) ---
  // Llama a /api/token/
  // Devuelve el AuthUser si es exitoso, o lanza una Excepción si falla.
  Future<AuthUser> login(String usernameOrEmail, String password) async {
    final Uri loginUrl = Uri.parse('$_baseUrl/token/');

    try {
      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        // El backend espera 'username' y 'password'
        body: jsonEncode(<String, String>{
          'username':
              usernameOrEmail, // El serializer acepta email o username aquí
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Login exitoso
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? accessToken = responseData['access'];
        final String? refreshToken = responseData['refresh'];

        if (accessToken != null && refreshToken != null) {
          // Guardamos los tokens
          await _saveTokens(accessToken, refreshToken);

          // Decodificamos el token para obtener los datos del usuario
          final Map<String, dynamic> decodedToken = Jwt.parseJwt(accessToken);
          final AuthUser authUser = AuthUser.fromJson(decodedToken);

          // Guardamos los datos del usuario
          await _saveUserData(authUser);

          print('✅ Login exitoso para: ${authUser.username}');
          return authUser;
        } else {
          throw Exception('Respuesta de API inválida: Faltan tokens.');
        }
      } else {
        // Manejo de errores (ej. 401 Credenciales incorrectas)
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage = errorData['detail'] ?? 'Error desconocido';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Captura errores de red, JSON, o excepciones lanzadas
      print('❌ Error en AuthService.login: $e');
      throw Exception('No se pudo conectar al servidor. Inténtalo de nuevo.');
    }
  }

  // --- Método de Registro (CU-21) ---
  // Llama a /api/users/register/
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    final Uri registerUrl = Uri.parse('$_baseUrl/users/register/');
    try {
      final response = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, dynamic>{
          'username': username,
          'email': email,
          'password': password,
          'password2': password2,
          // Por defecto, registramos como CLIENTE (ID 2)
          // Ver: backend.github: users/fixtures/roles.json
          'role_id': 2,
        }),
      );

      if (response.statusCode == 201) {
        // 201 Created = Registro exitoso
        print('✅ Registro exitoso para: $username');
        return true;
      } else {
        // Manejo de errores de registro (ej. 400 Bad Request)
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        // Formateamos los errores (ej. "username: ya existe")
        String errorMessage = _formatApiErrors(errorData);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error en AuthService.register: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // --- Método de Logout ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Borramos todos los datos de sesión
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    print('🧹 Sesión cerrada. Tokens eliminados.');
  }

  // --- Método para verificar sesión al inicio ---
  // Comprueba si hay un token válido y datos de usuario guardados
  Future<AuthUser?> getInitialAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString(_accessTokenKey);
    final String? userDataString = prefs.getString(_userDataKey);

    if (token == null || userDataString == null) {
      print('ℹ️ No hay sesión guardada.');
      return null; // No hay sesión
    }

    try {
      // Verificamos si el token ha expirado
      if (Jwt.isExpired(token)) {
        print('⚠️ Token expirado. Se requiere nuevo login.');
        await logout(); // Limpiamos los datos expirados
        return null;
      }

      // Si el token es válido, cargamos los datos del usuario
      final AuthUser user = AuthUser.fromJson(jsonDecode(userDataString));
      print('✅ Sesión válida encontrada para: ${user.username}');
      return user;
    } catch (e) {
      print('⚠️ Error al verificar token/datos guardados: $e');
      await logout(); // Limpiamos datos corruptos
      return null;
    }
  }

  // --- Helpers Internos ---

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> _saveUserData(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos la representación JSON de nuestro objeto AuthUser
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  // Helper para formatear errores de validación de la API de DRF
  String _formatApiErrors(Map<String, dynamic> errors) {
    List<String> messages = [];
    errors.forEach((field, errorList) {
      if (errorList is List) {
        messages.add('$field: ${errorList.join(', ')}');
      } else {
        messages.add('$field: $errorList');
      }
    });
    return messages.join('; ');
  }
}
