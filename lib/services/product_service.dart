// lib/services/product_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/models/review_model.dart';

class ProductService {
  static const String _baseUrl = 'https://smartsales-backend.onrender.com/api';
  static const String _productsEndpoint = '/products/';

  // --- MÉTODOS PÚBLICOS (CLIENTE) ---

  /// Obtiene la lista de productos (con filtro de búsqueda opcional)
  Future<List<Product>> getProducts({String? query}) async {
    Uri url;
    if (query != null && query.isNotEmpty) {
      url = Uri.parse(
        '$_baseUrl$_productsEndpoint',
      ).replace(queryParameters: {'search': query});
    } else {
      url = Uri.parse(_baseUrl + _productsEndpoint);
    }
    print('Llamando a la API: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> productListJson = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return productListJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Error de conexión: Revise su conexión a internet.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene un solo producto por su ID
  Future<Product> getProductById(int id) async {
    final Uri url = Uri.parse('$_baseUrl$_productsEndpoint$id/');
    print('Llamando a la API: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic productJson = jsonDecode(utf8.decode(response.bodyBytes));
        return Product.fromJson(productJson);
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

  /// Obtiene las reseñas de un producto
  Future<List<Review>> getReviews(int productId) async {
    final Uri url = Uri.parse('$_baseUrl$_productsEndpoint$productId/reviews/');
    print('Llamando a la API: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> reviewsJson = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return reviewsJson.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar reseñas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Publica una nueva reseña
  Future<void> postReview({
    required String token,
    required int productId,
    required double rating,
    required String comment,
  }) async {
    final Uri url = Uri.parse(
      '$_baseUrl$_productsEndpoint$productId/reviews/create/',
    );
    print('Publicando reseña en: $url');

    final body = jsonEncode({'rating': rating, 'comment': comment});

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception(
          'Error al publicar reseña: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- MÉTODOS DE ADMINISTRADOR (CRUD) ---

  /// Prepara el cuerpo (body) del POST/PUT
  Map<String, dynamic> _prepareProductBody({
    required String name,
    required String description,
    required double price,
    required int stock,
    required int categoryId,
    required int brandId,
    String? imageUrl,
  }) {
    return {
      'name': name,
      'description': description,
      'price': price.toString(), // Django espera el Decimal como String
      'stock': stock,
      'category_id': categoryId,
      'brand_id': brandId,
      if (imageUrl != null) 'image': imageUrl,
    };
  }

  /// Crea un nuevo producto.
  Future<Product> createProduct(
    String token,
    Map<String, dynamic> productData,
  ) async {
    final Uri url = Uri.parse('$_baseUrl$_productsEndpoint');
    print('Creando producto...');

    final body = jsonEncode(
      _prepareProductBody(
        name: productData['name'],
        description: productData['description'],
        price: productData['price'],
        stock: productData['stock'],
        categoryId: productData['category_id'],
        brandId: productData['brand_id'],
      ),
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        return Product.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception(
          'Error al crear: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualiza un producto existente.
  Future<Product> updateProduct(
    String token,
    int productId,
    Map<String, dynamic> productData,
  ) async {
    final Uri url = Uri.parse('$_baseUrl$_productsEndpoint$productId/');
    print('Actualizando producto: $url');

    final body = jsonEncode(
      _prepareProductBody(
        name: productData['name'],
        description: productData['description'],
        price: productData['price'],
        stock: productData['stock'],
        categoryId: productData['category_id'],
        brandId: productData['brand_id'],
      ),
    );

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception(
          'Error al actualizar: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Elimina un producto por su ID.
  Future<bool> deleteProduct(String token, int productId) async {
    final Uri url = Uri.parse('$_baseUrl$_productsEndpoint$productId/');
    print('Eliminando producto: $url');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Error al eliminar: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
