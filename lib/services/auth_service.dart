// lib/services/auth_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/user_model.dart';
import 'package:smartsales365/models/login_response_model.dart';
import 'package:smartsales365/services/api_service.dart';

class AuthService extends ApiService {
  // --- LOGIN ---
  // Retorna LoginResponse con access, refresh y user data
  // Endpoint: POST /api/token/
  // Basado en: MyTokenObtainPairView y MyTokenObtainPairSerializer
  Future<LoginResponse> login(String username, String password) async {
    try {
      print('🔐 Intentando login para: $username');
      print('🔍 URL de login: $baseUrl/token/');

      final response = await http
          .post(
            Uri.parse('$baseUrl/token/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Timeout en petición de login');
              throw Exception(
                'La petición tardó demasiado. Verifica tu conexión.',
              );
            },
          );

      print('📡 Status Code login: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Login exitoso');
        print(
          '👤 Usuario: ${data['user']['username']} (ID: ${data['user']['id']})',
        );
        print('🎭 Rol: ${data['user']['role'] ?? 'Sin rol'}');
        return LoginResponse.fromJson(data);
      } else {
        print('❌ Error de login: ${response.statusCode} - ${response.body}');
        throw Exception('Credenciales inválidas');
      }
    } catch (e) {
      print('❌ Excepción en login: $e');
      rethrow;
    }
  }

  // --- OBTENER PERFIL DE USUARIO ---
  // Endpoint: GET /api/users/users/{userId}/
  // Basado en: UserViewSet - filtra automáticamente por usuario autenticado
  // Alternativa: GET /api/users/users/ retorna lista con solo el usuario actual
  Future<UserProfile> getUserProfile(String token, int userId) async {
    try {
      print('👤 Obteniendo perfil de usuario ID: $userId');
      print('🔍 URL de perfil: $baseUrl/users/users/$userId/');

      final response = await http
          .get(
            Uri.parse('$baseUrl/users/users/$userId/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Timeout en petición de perfil');
              throw Exception(
                'La petición tardó demasiado. Verifica tu conexión.',
              );
            },
          );

      print('📡 Status Code perfil: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Perfil obtenido exitosamente');
        return UserProfile.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      } else {
        print('❌ Error al obtener perfil: ${response.statusCode}');
        handleResponse(response);
        throw Exception('Falló al cargar el perfil del usuario');
      }
    } catch (e) {
      print('❌ Excepción en getUserProfile: $e');
      rethrow;
    }
  }

  // --- OBTENER PERFIL ALTERNATIVO (usando lista filtrada) ---
  // Endpoint: GET /api/users/users/
  // El backend filtra automáticamente y retorna solo el usuario autenticado
  Future<UserProfile> getCurrentUserProfile(String token) async {
    try {
      print('👤 Obteniendo perfil del usuario actual');
      print('🔍 URL de perfil: $baseUrl/users/users/');

      final response = await http
          .get(
            Uri.parse('$baseUrl/users/users/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Timeout en petición de perfil');
              throw Exception(
                'La petición tardó demasiado. Verifica tu conexión.',
              );
            },
          );

      print('📡 Status Code perfil: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(utf8.decode(response.bodyBytes));
        if (users.isNotEmpty) {
          print('✅ Perfil obtenido exitosamente (de lista)');
          return UserProfile.fromJson(users.first);
        } else {
          throw Exception('No se encontró el usuario');
        }
      } else {
        print('❌ Error al obtener perfil: ${response.statusCode}');
        handleResponse(response);
        throw Exception('Falló al cargar el perfil del usuario');
      }
    } catch (e) {
      print('❌ Excepción en getCurrentUserProfile: $e');
      rethrow;
    }
  }

  // --- REGISTRO ---
  // Endpoint: POST /api/users/register/
  // Basado en: RegisterView - crea usuario y retorna mensaje + datos de usuario
  // Body: {username, email, password, password2, first_name?, last_name?, role_id?}
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      print('📝 Registrando nuevo usuario: ${data['username']}');
      print('🔍 URL de registro: $baseUrl/users/register/');

      final response = await http
          .post(
            Uri.parse('$baseUrl/users/register/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Timeout en petición de registro');
              throw Exception(
                'La petición tardó demasiado. Verifica tu conexión.',
              );
            },
          );

      print('📡 Status Code registro: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ Usuario registrado exitosamente');
        print('👤 Usuario creado: ${responseData['user']['username']}');
        return responseData;
      } else {
        print('❌ Error de registro: ${response.statusCode} - ${response.body}');
        handleResponse(response);
        throw Exception('Falló al registrar el usuario');
      }
    } catch (e) {
      print('❌ Excepción en register: $e');
      rethrow;
    }
  }

  // --- REFRESH TOKEN ---
  // Endpoint: POST /api/token/refresh/
  // Body: {refresh}
  // Retorna: {access}
  Future<String> refreshAccessToken(String refreshToken) async {
    try {
      print('🔄 Refrescando access token');
      print('🔍 URL de refresh: $baseUrl/token/refresh/');

      final response = await http
          .post(
            Uri.parse('$baseUrl/token/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Timeout en petición de refresh');
              throw Exception(
                'La petición tardó demasiado. Verifica tu conexión.',
              );
            },
          );

      print('📡 Status Code refresh: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Access token refrescado');
        return data['access'] as String;
      } else {
        print('❌ Error al refrescar token: ${response.statusCode}');
        throw Exception('Refresh token inválido o expirado');
      }
    } catch (e) {
      print('❌ Excepción en refreshAccessToken: $e');
      rethrow;
    }
  }
}
