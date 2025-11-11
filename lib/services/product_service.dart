// lib/services/product_service.dart

// ignore_for_file: avoid_print, prefer_is_empty

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/models/review_model.dart';
import 'package:smartsales365/services/api_service.dart';

class ProductService extends ApiService {
  final String _productsPath = 'products';

  // --- OBTENER (GET) todos los productos (con filtros opcionales) ---
  Future<List<Product>> getProducts({
    String? token,
    Map<String, dynamic>? filters,
  }) async {
    Uri uri = Uri.parse('$baseUrl/$_productsPath/');

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

    print('🔍 URL de productos: $uri');

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(uri, headers: headers);

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Product> products = body
            .map((dynamic item) => Product.fromJson(item))
            .toList();
        print('✅ ${products.length} productos cargados');
        return products;
      } else {
        throw Exception(
          'Falló al cargar productos: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error al cargar productos: $e');
      rethrow;
    }
  }

  // --- OBTENER (GET) un solo producto por ID ---
  Future<Product> getProductById(int productId, {String? token}) async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('🔍 Obteniendo producto ID: $productId');

    final response = await http.get(
      Uri.parse('$baseUrl/$_productsPath/$productId/'),
      headers: headers,
    );

    print('📡 Status producto detalle: ${response.statusCode}');

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      handleResponse(response);
      throw Exception('Falló al cargar el producto');
    }
  }

  // --- OBTENER (GET) reseñas de un producto ---
  // CORRECCIÓN: Manejo robusto con múltiples intentos y validación de respuesta
  Future<List<Review>> getReviews(int productId) async {
    try {
      // Endpoint correcto según backend: /api/reviews/?product_id={productId}
      final String url1 = '$baseUrl/reviews/?product_id=$productId';
      print('🔍 URL de reseñas (intento 1): $url1');

      final response1 = await http.get(
        Uri.parse(url1),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final parsed1 = _tryParseReviewsResponse(response1);
      if (parsed1 != null) {
        return parsed1;
      }

      // 2) Segundo intento: endpoint anidado bajo producto
      final String url2 = '$baseUrl/products/$productId/reviews/';
      print('� URL de reseñas (intento 2): $url2');

      final response2 = await http.get(
        Uri.parse(url2),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final parsed2 = _tryParseReviewsResponse(response2);
      if (parsed2 != null) {
        return parsed2;
      }

      // Si ninguno funcionó, regresar lista vacía para no romper la UI
      return [];
    } catch (e) {
      print('❌ Excepción al cargar reseñas: $e');
      // En lugar de lanzar excepción, devuelve lista vacía para evitar crash
      return [];
    }
  }

  // Intenta parsear la respuesta de reseñas; devuelve null si no es válida
  List<Review>? _tryParseReviewsResponse(http.Response response) {
    try {
      print('📡 Status Code reseñas: ${response.statusCode}');
      print('� Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final body =
              jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
          final reviews = body.map((e) => Review.fromJson(e)).toList();
          print('✅ ${reviews.length} reseñas cargadas correctamente');
          return reviews;
        } else {
          // Si llega HTML u otro tipo, log y retornar null para intentar fallback
          final preview = response.body.length > 200
              ? response.body.substring(0, 200)
              : response.body;
          print('⚠️ Respuesta no-JSON, preview: $preview');
          return null;
        }
      }

      if (response.statusCode == 404) {
        print('ℹ️ No hay reseñas (404)');
        return <Review>[];
      }

      print('❌ Error HTTP ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error al parsear respuesta de reseñas: $e');
      return null;
    }
  }

  // --- PUBLICAR (POST) una nueva reseña ---
  Future<void> postReview({
    required String token,
    required int productId,
    required double rating,
    String? comment,
  }) async {
    try {
      final url = '$baseUrl/reviews/';
      print('📝 Creando reseña en: $url');
      print('📦 Producto: $productId, Rating: $rating');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product': productId,
          'rating': rating,
          'comment': comment ?? '',
        }),
      );

      print('📡 Status Code post review: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Reseña creada exitosamente');
      } else {
        handleResponse(response);
        throw Exception('Error al publicar la reseña: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al publicar reseña: $e');
      rethrow;
    }
  }

  // --- (ADMIN) CREAR (POST) un nuevo producto ---
  Future<void> createProduct(String token, Map<String, dynamic> data) async {
    try {
      print('📝 Creando producto');

      final response = await http.post(
        Uri.parse('$baseUrl/$_productsPath/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('📡 Status create product: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('✅ Producto creado exitosamente');
      } else {
        handleResponse(response);
        throw Exception('Error al crear el producto');
      }
    } catch (e) {
      print('❌ Error al crear producto: $e');
      rethrow;
    }
  }

  // --- (ADMIN) ACTUALIZAR (PUT) un producto ---
  Future<void> updateProduct(
    String token,
    int productId,
    Map<String, dynamic> data,
  ) async {
    try {
      print('🔄 Actualizando producto ID: $productId');

      final response = await http.put(
        Uri.parse('$baseUrl/$_productsPath/$productId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('📡 Status update product: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Producto actualizado exitosamente');
      } else {
        handleResponse(response);
        throw Exception('Error al actualizar el producto');
      }
    } catch (e) {
      print('❌ Error al actualizar producto: $e');
      rethrow;
    }
  }

  // --- (ADMIN) ELIMINAR (DELETE) un producto ---
  Future<void> deleteProduct(String token, int productId) async {
    try {
      print('🗑️ Eliminando producto ID: $productId');

      final response = await http.delete(
        Uri.parse('$baseUrl/$_productsPath/$productId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Status delete product: ${response.statusCode}');

      if (response.statusCode == 204) {
        print('✅ Producto eliminado exitosamente');
      } else {
        handleResponse(response);
        throw Exception('Error al eliminar el producto');
      }
    } catch (e) {
      print('❌ Error al eliminar producto: $e');
      rethrow;
    }
  }
}
