// lib/services/product_service.dart

// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/models/review_model.dart';
import 'package:smartsales365/services/api_service.dart'; // Importa la clase base

// CORRECCIÓN: Asegúrate de que hereda de ApiService
class ProductService extends ApiService {
  // La URL base de productos ahora se construye desde el 'baseUrl' del ApiService
  final String _productsBaseUrl = '/products/products';

  // --- OBTENER (GET) todos los productos (con filtros opcionales) ---
  Future<List<Product>> getProducts({
    String? token,
    Map<String, dynamic>? filters,
  }) async {
    // Construye la URL con los parámetros de filtro
    // Usa 'baseUrl' de ApiService
    Uri uri = Uri.parse('$baseUrl$_productsBaseUrl/');
    if (filters != null && filters.isNotEmpty) {
      final validFilters = Map<String, dynamic>.from(
        filters,
      )..removeWhere((key, value) => value == null || value.toString().isEmpty);

      if (validFilters.isNotEmpty) {
        uri = uri.replace(
          queryParameters: validFilters.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }
    }

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Product> products = body
          .map((dynamic item) => Product.fromJson(item))
          .toList();
      return products;
    } else {
      throw Exception(
        'Falló al cargar productos: ${response.statusCode} ${response.body}',
      );
    }
  }

  // --- OBTENER (GET) un solo producto por ID ---
  Future<Product> getProductById(int productId, {String? token}) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$_productsBaseUrl/$productId/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      // Usa el 'handleResponse' de la clase base para un error limpio
      handleResponse(response);
      throw Exception('Falló al cargar el producto');
    }
  }

  // --- OBTENER (GET) reseñas de un producto ---
  Future<List<Review>> getReviews(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl$_productsBaseUrl/$productId/reviews/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Review> reviews = body
          .map((dynamic item) => Review.fromJson(item))
          .toList();
      return reviews;
    } else {
      handleResponse(response);
      throw Exception('Falló al cargar las reseñas');
    }
  }

  // --- PUBLICAR (POST) una nueva reseña ---
  Future<void> postReview({
    required String token,
    required int productId,
    required double rating,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_productsBaseUrl/$productId/reviews/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );

    if (response.statusCode != 201) {
      // 201 Created
      handleResponse(response);
      throw Exception('Error al publicar la reseña');
    }
  }

  // --- (ADMIN) CREAR (POST) un nuevo producto ---
  Future<void> createProduct(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$_productsBaseUrl/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      handleResponse(response);
      throw Exception('Error al crear el producto');
    }
  }

  // --- (ADMIN) ACTUALIZAR (PUT) un producto ---
  Future<void> updateProduct(
    String token,
    int productId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$_productsBaseUrl/$productId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      handleResponse(response);
      throw Exception('Error al actualizar el producto');
    }
  }

  // --- (ADMIN) ELIMINAR (DELETE) un producto ---
  Future<void> deleteProduct(String token, int productId) async {
    // CORRECCIÓN: Esta es la línea que tenía los 3 errores.
    // Se ha corregido 'Uri.Garantía(parse(...))' por 'Uri.parse(...)'.
    final response = await http.delete(
      Uri.parse('$baseUrl$_productsBaseUrl/$productId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      // 204 No Content
      handleResponse(response);
      throw Exception('Error al eliminar el producto');
    }
  }
}
