// lib/services/user_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/user_model.dart';
import 'package:smartsales365/models/role_model.dart';

class UserService {
  final String _baseUrl =
      'https://smartsales-backend-891739940726.us-central1.run.app/api';

  // --- OBTENER (GET) todos los usuarios ---
  Future<List<User>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<User> users = body
          .map((dynamic item) => User.fromJson(item))
          .toList();
      return users;
    } else {
      throw Exception('Falló al cargar los usuarios');
    }
  }

  // --- OBTENER (GET) todos los roles ---
  Future<List<Role>> getRoles(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/roles/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Role> roles = body
          .map((dynamic item) => Role.fromJson(item))
          .toList();
      return roles;
    } else {
      throw Exception('Falló al cargar los roles');
    }
  }

  // --- ACTUALIZAR (PATCH) el rol de un usuario ---
  Future<void> updateUserRole(
    String token,
    int userId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/users/$userId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data), // Se envía {'role_id': ID}
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar rol: ${response.statusCode} ${response.body}',
      );
    }
  }

  // --- ¡NUEVO MÉTODO AÑADIDO! ---
  // --- ACTUALIZAR (PATCH) detalles de un usuario ---
  Future<void> updateUser(
    String token,
    int userId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/users/$userId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar usuario: ${response.statusCode} ${response.body}',
      );
    }
  }

  // --- ELIMINAR (DELETE) un usuario ---
  Future<void> deleteUser(String token, int userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/$userId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      // 204 No Content
      throw Exception('Error al eliminar usuario: ${response.statusCode}');
    }
  }
}
