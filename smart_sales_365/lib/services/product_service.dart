// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sales_365/models/product_model.dart';

import 'package:smart_sales_365/models/category_model.dart';
import 'package:smart_sales_365/models/brand_model.dart';
import 'package:smart_sales_365/models/review_model.dart';

class ProductService {
  final String baseUrl =
      'http://10.0.2.2:8000/api/products'; // Emulador Android

  Future<List<Product>> getProducts({Map<String, String>? params}) async {
    // --- CORRECCIÓN LINTER ---
    var uri = Uri.parse('$baseUrl/'); // Usar interpolación
    // --- FIN CORRECIÓN ---

    if (params != null && params.isNotEmpty) {
      final activeParams =
          Map.fromEntries(params.entries.where((e) => e.value.isNotEmpty));
      uri = uri.replace(queryParameters: activeParams);
    }
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Product> getProductById(int id) async {
    // --- CORRECCIÓN LINTER ---
    final response =
        await http.get(Uri.parse('$baseUrl/$id/')); // Usar interpolación
    // --- FIN CORRECIÓN ---
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<List<Category>> getCategories() async {
    // --- CORRECCIÓN LINTER ---
    final response =
        await http.get(Uri.parse('$baseUrl/categories/')); // Usar interpolación
    // --- FIN CORRECIÓN ---
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      return data.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Brand>> getBrands() async {
    // --- CORRECCIÓN LINTER ---
    final response =
        await http.get(Uri.parse('$baseUrl/brands/')); // Usar interpolación
    // --- FIN CORRECIÓN ---
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      return data.map((item) => Brand.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load brands');
    }
  }

  // --- FUNCIONES DE RESEÑAS AÑADIDAS (sincronizadas con product_detail_screen) ---

  /// Obtiene la lista de reseñas para un producto
  Future<List<Review>> getReviews(int productId) async {
    final response = await http.get(Uri.parse('$baseUrl/$productId/reviews/'));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      return data.map((item) => Review.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  /// Publica una nueva reseña
  Future<Review> postReview({
    required int productId,
    required double rating,
    required String comment,
  }) async {
    // 1. Obtener el token de autenticación
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('No estás autenticado. Inicia sesión para opinar.');
    }

    // 2. Enviar la solicitud POST
    final response = await http.post(
      Uri.parse('$baseUrl/$productId/reviews/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({
        'rating': rating,
        'comment': comment,
      }),
    );

    // 3. Manejar la respuesta
    if (response.statusCode == 201) {
      // Creado exitosamente
      return Review.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else if (response.statusCode == 400) {
      // Error de validación (ej. ya opinó)
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Error al enviar la reseña');
    } else if (response.statusCode == 401) {
      throw Exception('Token inválido. Inicia sesión de nuevo.');
    } else {
      throw Exception('Error al enviar la reseña (${response.statusCode})');
    }
  }
}
