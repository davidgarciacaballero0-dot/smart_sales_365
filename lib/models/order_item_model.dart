// lib/models/order_item_model.dart
import 'package:smartsales365/models/product_model.dart';

/// Modelo OrderItem que refleja OrderItemSerializer del backend
/// Almacena el precio al momento de la compra (historial)
class OrderItem {
  final int id;
  final Product product; // ProductSerializer completo anidado
  final int quantity;
  final double price; // Precio unitario al momento de la compra
  final double itemPrice; // Calculado: quantity * price

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.itemPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      price: _parseDouble(json['price']),
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

  // Helper para verificar si itemPrice coincide con quantity * price
  bool get priceIsConsistent {
    return (quantity * price - itemPrice).abs() < 0.01;
  }
}
