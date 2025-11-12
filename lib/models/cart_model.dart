// lib/models/cart_model.dart

import 'package:smartsales365/models/cart_item_model.dart';

/// Modelo Cart que refleja CartSerializer del backend
/// Representa el carrito completo con todos sus items
class Cart {
  final int id;
  final int userId;
  final List<CartItem> items;
  final double totalPrice; // Calculado en backend
  final int itemsCount; // Número total de items
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.itemsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<CartItem> cartItems = itemsList
        .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
        .toList();

    return Cart(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user']),
      items: cartItems,
      totalPrice: _parseDouble(json['total_price']),
      itemsCount: json['items_count'] as int? ?? cartItems.length,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper methods
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Calcula el número total de productos sumando todas las cantidades
  int get totalQuantity {
    if (items.isEmpty) return 0;
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Find item by product ID
  CartItem? findItemByProductId(int productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Check if product is in cart
  bool containsProduct(int productId) {
    return items.any((item) => item.productId == productId);
  }
}
