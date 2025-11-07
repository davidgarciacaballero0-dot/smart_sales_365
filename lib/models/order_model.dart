// lib/models/order_model.dart
import 'package:smartsales365/models/order_item_model.dart';

class Order {
  final int id;
  final double totalPrice;
  final String paymentStatus; // ej: "completed", "pending"
  final DateTime createdAt;
  final List<OrderItem> items; // Una lista de los ítems del pedido

  Order({
    required this.id,
    required this.totalPrice,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Convertimos la lista de JSON 'items' en una lista de objetos 'OrderItem'
    var itemsList = json['items'] as List;
    List<OrderItem> orderItems = itemsList
        .map((i) => OrderItem.fromJson(i))
        .toList();

    return Order(
      id: json['id'],
      totalPrice: double.parse(json['total_price']),
      paymentStatus: json['payment_status'],
      // Convertimos el String de la fecha (ISO 8601) a un objeto DateTime de Dart
      createdAt: DateTime.parse(json['created_at']),
      items: orderItems,
    );
  }
}
