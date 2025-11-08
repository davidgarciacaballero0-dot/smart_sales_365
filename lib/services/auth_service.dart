// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl =
      "https://smartsales-backend-891739940726.us-central1.run.app/api";
  final _secureStorage = const FlutterSecureStorage();

  // --- Almacenamiento de Tokens (Sin cambios) ---

  Future<void> _saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }

  Future<void> _saveRefreshToken(String token) async {
    await _secureStorage.write(key: 'refreshToken', value: token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> _deleteAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await _secureStorage.delete(key: 'refreshToken');
  }

  // --- Lógica de API (Login, Refresh, Logout - Sin cambios) ---

  // 1. Iniciar Sesión (api/token/)
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/token/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAccessToken(data['access']);
        await _saveRefreshToken(data['refresh']);
        return {'success': true, 'access': data['access']};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error de inicio de sesión',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 2. Refrescar Token (api/token/refresh/)
  Future<bool> refreshToken() async {
    final url = Uri.parse('$_baseUrl/token/refresh/');
    final refreshToken = await _secureStorage.read(key: 'refreshToken');

    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAccessToken(data['access']);
        return true;
      } else {
        await _deleteAllTokens();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 3. Cerrar Sesión
  Future<void> logout() async {
    await _deleteAllTokens();
  }

  // 4. REGISTRO (Sin cambios)
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    // ... (código existente) ...
    final url = Uri.parse('$_baseUrl/users/register/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
        }),
      );
      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = errorData.toString();
        if (errorData is Map) {
          errorMessage = errorData.entries
              .map((e) => '${e.key}: ${e.value.join(", ")}')
              .join("\n");
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // --- ¡NUEVO MÉTODO! ---

  /// 5. Obtiene el perfil del usuario (incluyendo el ROL)
  ///    usando el token de acceso.
  Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    // Este endpoint (api/users/me/) está protegido y devuelve
    // los datos del usuario basado en el token.
    final url = Uri.parse('$_baseUrl/users/me/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        // Devuelve el perfil del usuario (ej. {'id': 1, 'username': 'admin', 'role': 'admin'})
        return {'success': true, 'user': data};
      } else {
        return {'success': false, 'message': 'Error al obtener el perfil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
