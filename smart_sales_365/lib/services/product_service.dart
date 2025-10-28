// lib/services/product_service.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_sales_365/models/product_model.dart'; // Importamos el modelo

class ProductService {
  // La misma URL base que usamos en AuthService
  final String _baseUrl = 'https://smartsales-backend.onrender.com/api';

  // --- Método para obtener la lista de productos ---
  // Llama a GET /api/products/
  // Devuelve una lista de objetos Product o lanza una Excepción.
  Future<List<Product>> fetchProducts() async {
    final Uri productsUrl = Uri.parse('$_baseUrl/products/');

    try {
      final response = await http.get(
        productsUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          // NOTA: Si tu endpoint requiere autenticación para ver productos,
          // deberás añadir el token aquí, similar a como lo haríamos
          // para el carrito o las órdenes. Por ahora, asumimos que es público.
          // 'Authorization': 'Bearer TU_ACCESS_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        // La API devuelve una lista de objetos JSON directamente
        // Decodificamos el cuerpo de la respuesta (que es un String JSON)
        // en una List<dynamic>, donde cada 'dynamic' es un Map<String, dynamic>
        List<dynamic> productListJson = jsonDecode(response.body);

        // Mapeamos cada objeto JSON a un objeto Product usando el factory
        List<Product> products = productListJson
            .map(
              (jsonItem) => Product.fromJson(jsonItem as Map<String, dynamic>),
            )
            .toList();

        print('✅ Productos obtenidos: ${products.length}');
        return products;
      } else {
        // Manejo de errores si la API no devuelve 200 OK
        print(
          '❌ Error al obtener productos (${response.statusCode}): ${response.body}',
        );
        throw Exception('Error al cargar los productos del servidor.');
      }
    } catch (e) {
      // Captura errores de red, JSON, etc.
      print('❌ Error en ProductService.fetchProducts: $e');
      throw Exception(
        'No se pudo conectar al servidor para obtener productos.',
      );
    }
  }

  // --- (Opcional) Método para obtener un solo producto por ID ---
  // Llama a GET /api/products/{id}/
  Future<Product?> fetchProductById(int productId) async {
    final Uri productUrl = Uri.parse('$_baseUrl/products/$productId/');
    try {
      final response = await http.get(
        productUrl,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          // Añadir Authorization si es necesario
        },
      );
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        print(
          '❌ Error al obtener producto $productId (${response.statusCode}): ${response.body}',
        );
        return null; // O lanzar excepción si prefieres
      }
    } catch (e) {
      print('❌ Error en ProductService.fetchProductById: $e');
      return null; // O lanzar excepción
    }
  }
}
