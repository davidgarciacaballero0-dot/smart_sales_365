// lib/models/products_response_model.dart

import 'package:smartsales365/models/product_model.dart';

/// Modelo para manejar respuestas de productos del backend
/// El backend puede retornar:
/// 1. Array directo: [Product, Product, ...]
/// 2. Respuesta paginada: {count: X, next: URL, previous: URL, results: [...]}
class ProductsResponse {
  final List<Product> products;
  final int? count; // Total de productos (solo en respuesta paginada)
  final String? next; // URL para siguiente página (solo en respuesta paginada)
  final String?
  previous; // URL para página anterior (solo en respuesta paginada)

  ProductsResponse({
    required this.products,
    this.count,
    this.next,
    this.previous,
  });

  /// Factory para crear desde JSON (maneja ambos formatos)
  factory ProductsResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic> && json.containsKey('results')) {
      // Formato paginado
      return ProductsResponse(
        products: (json['results'] as List)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList(),
        count: json['count'] as int?,
        next: json['next'] as String?,
        previous: json['previous'] as String?,
      );
    } else if (json is List) {
      // Array directo
      return ProductsResponse(
        products: json
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } else {
      throw Exception('Formato de respuesta de productos inválido');
    }
  }

  /// Verifica si hay más páginas disponibles
  bool get hasNextPage => next != null;

  /// Verifica si hay página anterior disponible
  bool get hasPreviousPage => previous != null;

  /// Verifica si la respuesta está paginada
  bool get isPaginated => count != null;
}
