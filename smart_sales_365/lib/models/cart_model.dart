// lib/models/cart_model.dart
import 'package:flutter/foundation.dart';
import 'package:smart_sales_365/models/cart_item_model.dart'; // Necesitamos CartItem

@immutable
class Cart {
  final int id; // ID del Carrito en la base de datos
  final int userId; // ID del usuario dueño del carrito
  final List<CartItem> items; // Lista de items en el carrito
  final double total; // Suma de subtotales (calculado en el backend)

  const Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
  });

  // Constructor factory para crear desde JSON
  // Basado en CartSerializer
  factory Cart.fromJson(Map<String, dynamic> json) {
    // Extraemos la lista de items del JSON
    var itemsListFromJson = json['items'] as List<dynamic>? ?? [];
    // Convertimos cada item JSON a un objeto CartItem
    List<CartItem> cartItemsList = itemsListFromJson
        .map((itemJson) => CartItem.fromJson(itemJson as Map<String, dynamic>))
        .toList();

    return Cart(
      id: json['id'] as int,
      userId: json['user'] as int, // El serializer devuelve 'user' (ID)
      items: cartItemsList,
      // Convertimos el total (String/Decimal en JSON) a double
      total: double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  // Método para convertir a JSON (útil para debug)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      // Convertimos cada CartItem de la lista a JSON
      'items': items.map((item) => item.toJson()).toList(),
      'total': total.toString(),
    };
  }
}
