// lib/models/order_item_model.dart
import 'package:smartsales365/models/product_model.dart';

class OrderItem {
  final int id;
  final Product product; // Tu serializador anida el producto completo
  final int quantity;
  final double price; // El precio al momento de la compra

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      // Usamos el constructor de Product.fromJson que ya teníamos
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      price: double.parse(json['price']),
    );
  }
}
