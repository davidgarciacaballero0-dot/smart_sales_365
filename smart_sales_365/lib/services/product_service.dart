// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/models/category_model.dart';
import 'package:smart_sales_365/models/brand_model.dart';
import 'package:smart_sales_365/models/review_model.dart'; // <-- AÑADIDO

class ProductService {
  final String baseUrl =
      'http://10.0.2.2:8000/api/products'; // Emulador Android

  Future<List<Product>> getProducts({Map<String, String>? params}) async {
    var uri = Uri.parse(baseUrl + '/');

    if (params != null && params.isNotEmpty) {
      final activeParams = Map.fromEntries(
        params.entries.where((e) => e.value.isNotEmpty),
      );
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
    final response = await http.get(Uri.parse('$baseUrl/$id/'));
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories/'));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      return data.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Brand>> getBrands() async {
    final response = await http.get(Uri.parse('$baseUrl/brands/'));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      return data.map((item) => Brand.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load brands');
    }
  }

  // --- NUEVAS FUNCIONES DE RESEÑAS AÑADIDAS ---

  Future<List<Review>> getReviews(int productId) async {
    final response = await http.get(Uri.parse('$baseUrl/$productId/reviews/'));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      return data.map((item) => Review.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<Review> postReview({
    required int productId,
    required double rating,
    required String comment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('No estás autenticado. Inicia sesión para opinar.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$productId/reviews/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({'rating': rating, 'comment': comment}),
    );

    if (response.statusCode == 201) {
      return Review.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else if (response.statusCode == 400) {
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Error al enviar la reseña');
    } else if (response.statusCode == 401) {
      throw Exception('Token inválido. Inicia sesión de nuevo.');
    } else {
      throw Exception('Error al enviar la reseña (${response.statusCode})');
    }
  }

  // --- FIN DE NUEVAS FUNCIONES ---
}
