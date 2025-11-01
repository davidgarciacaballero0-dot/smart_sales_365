// lib/services/auth_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sales_365/models/user_model.dart';

class AuthService {
  // Asegúrate que esta IP sea correcta para tu emulador/dispositivo
  final String baseUrl =
      'http://10.0.2.2:8000/api/users'; // IP para Emulador Android
  // final String baseUrl = 'http://127.0.0.1:8000/api/users'; // IP para iOS Sim/localhost

  // --- NUEVA FUNCIÓN HELPER ---
  // Esta función convierte el JSON de error de Django en un string legible
  String _parseError(Map<String, dynamic> errorData) {
    String message = "";
    if (errorData.containsKey('non_field_errors')) {
      // Error general (ej. "Usuario o contraseña incorrectos")
      message = errorData['non_field_errors'].join("\n");
    } else {
      // Errores específicos de campos (ej. "email: [este email ya existe]")
      errorData.forEach((key, value) {
        if (value is List) {
          message += "$key: ${value.join(", ")}\n";
        } else {
          message += "$key: $value\n";
        }
      });
    }
    return message.trim();
  }
  // --- FIN DE LA NUEVA FUNCIÓN ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return {'token': data['token'], 'user': data['user']};
    } else {
      // --- MODIFICACIÓN DE MANEJO DE ERROR ---
      try {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        // Lanza una excepción con el mensaje del backend
        throw Exception(_parseError(errorData));
      } catch (e) {
        // Si el error no es JSON, lanza un error genérico
        if (e is Exception) rethrow; // Vuelve a lanzar la excepción parseada
        throw Exception('Error al iniciar sesión: ${response.statusCode}');
      }
      // --- FIN DE LA MODIFICACIÓN ---
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return {'token': data['token'], 'user': data['user']};
    } else {
      // --- MODIFICACIÓN DE MANEJO DE ERROR ---
      try {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        // Lanza una excepción con el mensaje del backend
        throw Exception(_parseError(errorData));
      } catch (e) {
        // Si el error no es JSON, lanza un error genérico
        if (e is Exception) rethrow; // Vuelve a lanzar la excepción parseada
        throw Exception('Error al registrar: ${response.statusCode}');
      }
      // --- FIN DE LA MODIFICACIÓN ---
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );
      } catch (e) {
        // No importa si falla el logout en el backend, borramos localmente
      }
    }
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return User.fromJson(data);
    } else {
      // Si el token no es válido, borramos los datos
      await prefs.remove('token');
      await prefs.remove('user');
      return null;
    }
  }
}
