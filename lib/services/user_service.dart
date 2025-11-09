// lib/services/user_service.dart

// ignore_for_file: unused_import

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/user_model.dart';
import 'package:smartsales365/models/role_model.dart';
import 'package:smartsales365/services/api_service.dart';

class UserService {
  // _baseUrl ahora es
  final String _baseUrl =
      'https://smartsales-backend-891739940726.us-central1.run.app/api';

  // 1. OBTENER (GET) todos los usuarios
  Future<List<User>> getUsers(String token) async {
    // URL CORRECTA: '.../api' + '/users/'
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

  // 2. OBTENER (GET) todos los roles
  Future<List<Role>> getRoles(String token) async {
    // URL CORRECTA: '.../api' + '/users/roles/'
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

  // 3. ACTUALIZAR (PATCH) el rol de un usuario
  Future<void> updateUserRole(String token, int userId, int roleId) async {
    // URL CORRECTA: '.../api' + '/users/<id>/'
    final response = await http.patch(
      Uri.parse('$_baseUrl/users/$userId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': roleId}),
    );

    if (response.statusCode != 200) {
      try {
        Map<String, dynamic> errorBody = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        throw Exception(
          'Error al actualizar usuario: ${errorBody['detail'] ?? 'Error desconocido'}',
        );
      } catch (e) {
        throw Exception('Error al actualizar usuario: ${response.statusCode}');
      }
    }
  }

  // 4. ELIMINAR (DELETE) un usuario
  Future<void> deleteUser(String token, int userId) async {
    // URL CORRECTA: '.../api' + '/users/<id>/'
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
