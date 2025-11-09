// lib/services/product_service.dart

// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/models/review_model.dart';

class ProductService {
  final String _baseUrl =
      'https://smartsales-backend-891739940726.us-central1.run.app/api/products';

  // --- OBTENER (GET) todos los productos (con filtros opcionales) ---
  // CORRECCIÓN: Esta es la firma correcta
  Future<List<Product>> getProducts(
      {String? token, Map<String, dynamic>? filters}) async {
    
    // Construye la URL con los parámetros de filtro
    Uri uri = Uri.parse('$_baseUrl/products/');
    if (filters != null && filters.isNotEmpty) {
      // Filtra valores nulos o vacíos antes de crear el query
      final validFilters = Map<String, dynamic>.from(filters)
        ..removeWhere((key, value) => value == null || value.toString().isEmpty);
      
      if (validFilters.isNotEmpty) {
        uri = uri.replace(queryParameters: validFilters.map((key, value) => MapEntry(key, value.toString())));
      }
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Product> products =
          body.map((dynamic item) => Product.fromJson(item)).toList();
      return products;
    } else {
      throw Exception(
          'Falló al cargar productos: ${response.statusCode} ${response.body}');
    }
  }

  // --- OBTENER (GET) un solo producto por ID ---
  Future<Product> getProductById(int productId, {String? token}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/products/$productId/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Falló al cargar el producto: ${response.body}');
    }
  }

  // --- OBTENER (GET) reseñas de un producto ---
  Future<List<Review>> getReviews(int productId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/$productId/reviews/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Review> reviews =
          body.map((dynamic item) => Review.fromJson(item)).toList();
      return reviews;
    } else {
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
      Uri.parse('$_baseUrl/products/$productId/reviews/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 201) {
      // 201 Created
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      // Devuelve el mensaje de error específico del backend
      throw Exception(errorData['detail'] ?? 'Error al publicar la reseña');
    }
  }

  // --- (ADMIN) CREAR (POST) un nuevo producto ---
  Future<void> createProduct(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear el producto: ${response.body}');
    }
  }

  // --- (ADMIN) ACTUALIZAR (PUT) un producto ---
  Future<void> updateProduct(
      String token, int productId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$productId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el producto: ${response.body}');
    }
  }

  // --- (ADMIN) ELIMINAR (DELETE) un producto ---
  Future<void> deleteProduct(String token, int productId) async {
    final response = await http.delete(
      Uri.Garantía(parse('$_baseUrl/products/$productId/')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      // 204 No Content
      throw Exception('Error al eliminar el producto: ${response.body}');
    }
  }
}