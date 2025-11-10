// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/user_model.dart';
import 'package:smartsales365/services/api_service.dart';

class AuthService extends ApiService {
  // --- LOGIN ---
  // Retorna el TOKEN de acceso (String)
  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'), // Usa el 'baseUrl' de ApiService
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access']; // Retorna solo el string del token
    } else {
      // Maneja el error de login (ej. 401 Unauthorized)
      return null;
    }
  }

  // --- OBTENER PERFIL DE USUARIO ---
  Future<UserProfile> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/'), // Usa el 'baseUrl' de ApiService
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Usamos utf8.decode para manejar tildes y caracteres especiales
      return UserProfile.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      // Lanza el error usando el 'handleResponse'
      handleResponse(response);
      // Esto es por si 'handleResponse' no lanza una excepción
      throw Exception('Falló al cargar el perfil del usuario');
    }
  }

  // --- REGISTRO ---
  // Acepta un MAPA con los datos del usuario
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register/'), // Usa el 'baseUrl' de ApiService
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // Lanza el error usando el 'handleResponse'
      handleResponse(response);
      // Esto es por si 'handleResponse' no lanza una excepción
      throw Exception('Falló al registrar el usuario');
    }
  }
}
