// lib/models/cart_item_model.dart

import 'package:smartsales365/models/product_model.dart';

/// Modelo CartItem que refleja CartItemSerializer del backend
class CartItem {
  final int id;
  final Product product;
  final int productId; // Viene de product_id en serializer
  int quantity;
  final double itemPrice; // Calculado en backend: quantity * product.price

  CartItem({
    required this.id,
    required this.product,
    required this.productId,
    required this.quantity,
    required this.itemPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
      itemPrice: _parseDouble(json['item_price']),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'product_id': productId,
      'quantity': quantity,
      'item_price': itemPrice,
    };
  }

  // Helper methods
  void increment() {
    quantity++;
  }

  void decrement() {
    if (quantity > 1) {
      quantity--;
    }
  }

  // Check if quantity exceeds stock
  bool exceedsStock() {
    return quantity > product.stock;
  }
}
