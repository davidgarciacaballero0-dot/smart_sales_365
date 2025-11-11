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
      id: json['id'] as int,
      userId: json['user'] as int,
      items: cartItems,
      totalPrice: _parseDouble(json['total_price']),
      itemsCount: json['items_count'] as int? ?? cartItems.length,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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
