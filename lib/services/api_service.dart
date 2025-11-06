// lib/services/api_service.dart

import 'dart:convert'; // Para decodificar (JSON) y codificar (UTF-8)
import 'dart:io'; // Para capturar errores de conexión (SocketException)
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/product_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Para guardar el token

class ApiService {
  // La URL base de tu backend desplegado en Render
  static const String _baseUrl = 'https://smartsales-backend.onrender.com/api';

  // --- Endpoints de la API ---
  static const String _productsEndpoint = '/products/';
  static const String _usersEndpoint = '/users/';

  // Instancia para el almacenamiento seguro del token
  // 'const' significa que esta instancia se crea una sola vez
  final _storage = const FlutterSecureStorage();

  // --- MÉTODOS DE PRODUCTOS (ACCESO PÚBLICO) ---

  /// Obtiene la lista completa de productos desde el catálogo.
  Future<List<Product>> getProducts() async {
    final Uri url = Uri.parse(_baseUrl + _productsEndpoint);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Usamos utf8.decode para asegurar que lea bien las tildes y 'ñ'
        final List<dynamic> productListJson = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final List<Product> products = productListJson
            .map((json) => Product.fromJson(json))
            .toList();
        return products;
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } on SocketException {
      // Esto captura errores si no hay internet
      throw Exception('Error de conexión: Revise su conexión a internet.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene un solo producto usando su ID.
  Future<Product> getProductById(int id) async {
    final Uri url = Uri.parse('$_baseUrl$_productsEndpoint$id/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic productJson = jsonDecode(utf8.decode(response.bodyBytes));
        return Product.fromJson(productJson);
      } else if (response.statusCode == 404) {
        throw Exception('Producto no encontrado (404)');
      } else {
        throw Exception(
          'Error al cargar el producto $id: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('Error de conexión: Revise su conexión a internet.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // --- MÉTODOS DE AUTENTICACIÓN (LOGIN/LOGOUT) ---

  /// Inicia sesión de un usuario enviando email y password.
  /// Devuelve 'true' si fue exitoso, 'false' si no.
  Future<bool> login(String email, String password) async {
    // URL: .../api/users/login/
    final Uri url = Uri.parse('$_baseUrl$_usersEndpoint' + 'login/');

    try {
      final response = await http.post(
        url,
        headers: {
          // Es vital decirle al backend que le estamos enviando JSON
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // 'jsonEncode' convierte un Mapa de Dart en un String de JSON
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Éxito. Decodificamos la respuesta
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final String? token =
            data['token']; // 'token' es la clave que usa tu backend

        if (token != null) {
          // ¡Guardamos el token de forma segura!
          await _storage.write(key: 'authToken', value: token);
          return true; // Login exitoso
        } else {
          return false; // El backend no devolvió un token
        }
      } else {
        // Email o contraseña incorrectos (Error 400) u otro error
        return false;
      }
    } on SocketException {
      throw Exception('Error de conexión: Revise su conexión a internet.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Cierra la sesión borrando el token del almacenamiento seguro.
  Future<void> logout() async {
    await _storage.delete(key: 'authToken');
  }

  /// Obtiene el token guardado (para revisar si ya hay sesión).
  Future<String?> getToken() async {
    return await _storage.read(key: 'authToken');
  }

  // --- (PRÓXIMOS PASOS) ---
  // Aquí agregaremos métodos que *usan* el token guardado, como:
  // Future<void> createOrder(Cart cart) async {
  //   final token = await getToken();
  //   final response = await http.post(..., headers: {
  //     'Authorization': 'Token $token'
  //   });
  // }
}
