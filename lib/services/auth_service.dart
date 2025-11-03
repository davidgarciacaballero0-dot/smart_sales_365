import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = "https://smartsales-backend.onrender.com/api";
  final _secureStorage = const FlutterSecureStorage();

  // --- Almacenamiento de Tokens ---

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

  // --- Lógica de API ---

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

  // 4. REGISTRO (¡NUEVA FUNCIÓN!)
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final url = Uri.parse('$_baseUrl/users/register/'); // Endpoint de registro

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
}
