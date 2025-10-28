// lib/models/cart_item_model.dart
import 'package:flutter/foundation.dart';
import 'package:smart_sales_365/models/product_model.dart'; // Necesitamos el modelo Product

@immutable
class CartItem {
  final int id; // ID del CartItem en la base de datos
  final int quantity; // Cantidad de este producto en el carrito
  final double subtotal; // Precio * Cantidad (calculado en el backend)
  final Product
  productDetails; // Objeto Product completo (del serializer anidado)

  const CartItem({
    required this.id,
    required this.quantity,
    required this.subtotal,
    required this.productDetails,
  });

  // Constructor factory para crear desde JSON
  // Basado en CartItemSerializer
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      quantity: json['quantity'] as int,
      // Convertimos el subtotal (String/Decimal en JSON) a double
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0,
      // El serializer anidado 'product_details' contiene el objeto Product
      productDetails: Product.fromJson(
        json['product_details'] as Map<String, dynamic>,
      ),
    );
  }

  // Método para convertir a JSON (útil para debug)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'subtotal': subtotal.toString(),
      'product_details': productDetails.toJson(),
    };
  }
}
