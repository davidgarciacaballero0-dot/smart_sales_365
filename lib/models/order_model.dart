// lib/models/order_model.dart
import 'package:smartsales365/models/order_item_model.dart';

/// Modelo Order que refleja EXACTAMENTE OrderSerializer del backend
/// Incluye TODOS los campos del modelo Order de Django
class Order {
  final int id;
  final int userId;
  final String? username; // StringRelatedField del serializer

  // Status - PENDIENTE, PAGADO, ENVIADO, CANCELADO
  final String status;

  final double totalPrice;

  // Shipping info (opcional)
  final String? shippingAddress;
  final String? shippingPhone;

  // Stripe payment fields
  final String? stripeCheckoutId;
  final String? paymentStatus; // pendiente, pagado, fallido

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Items de la orden
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    this.username,
    required this.status,
    required this.totalPrice,
    this.shippingAddress,
    this.shippingPhone,
    this.stripeCheckoutId,
    this.paymentStatus,
    required this.createdAt,
    this.updatedAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Convertimos la lista de JSON 'items' en una lista de objetos 'OrderItem'
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> orderItems = itemsList
        .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id'] as int,
      userId: json['user'] as int,
      username: json['username'] as String?,
      status: json['status'] as String? ?? 'PENDIENTE',
      totalPrice: _parseDouble(json['total_price']),
      shippingAddress: json['shipping_address'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      stripeCheckoutId: json['stripe_checkout_id'] as String?,
      paymentStatus: json['payment_status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: orderItems,
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

  // Helper getters
  bool get isPending => status == 'PENDIENTE';
  bool get isPaid => status == 'PAGADO';
  bool get isShipped => status == 'ENVIADO';
  bool get isCancelled => status == 'CANCELADO';

  bool get isPaymentPending => paymentStatus == 'pendiente';
  bool get isPaymentCompleted => paymentStatus == 'pagado';
  bool get isPaymentFailed => paymentStatus == 'fallido';
}
