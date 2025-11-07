// lib/services/product_service.dart
// ignore_for_file: avoid_print

import 'dart:convert'; // Para decodificar JSON
import 'dart:io'; // Para manejar errores de conexión
import 'package:http/http.dart' as http;
// Asegúrate de que esta ruta a tu modelo es correcta
import 'package:smartsales365/models/product_model.dart';

class ProductService {
  // URL base de tu API en Render
  static const String _baseUrl = 'https://smartsales-backend.onrender.com/api';
  // Endpoint de productos
  static const String _productsEndpoint = '/products/';

  /// Obtiene la lista de productos.
  /// Acepta un [query] opcional para filtrar por búsqueda (search).
  Future<List<Product>> getProducts({String? query}) async {
    Uri url;
    if (query != null && query.isNotEmpty) {
      // Si hay una búsqueda, la añadimos como parámetro:
      // .../api/products/?search=televisor
      // Tu backend de Django REST Framework lo entenderá automáticamente.
      url = Uri.parse(
        '$_baseUrl$_productsEndpoint',
      ).replace(queryParameters: {'search': query});
    } else {
      // Si no hay búsqueda, es la URL normal
      url = Uri.parse(_baseUrl + _productsEndpoint);
    }

    // Imprimimos la URL en la consola para depurar.
    // ¡Muy útil para ver qué estamos pidiendo!
    print('Llamando a la API: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Éxito
        final List<dynamic> productListJson = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return productListJson.map((json) => Product.fromJson(json)).toList();
      } else {
        // Error del servidor
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } on SocketException {
      // Error de conexión (sin internet)
      throw Exception('Error de conexión: Revise su conexión a internet.');
    } catch (e) {
      // Cualquier otro error
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene un solo producto por su ID (Público)
  /// (Lo usaremos en el siguiente paso)
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
}
