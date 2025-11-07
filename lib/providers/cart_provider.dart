// lib/providers/cart_provider.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/cart_item_model.dart';
import 'package:smartsales365/models/product_model.dart';

class CartProvider with ChangeNotifier {
  // Lista privada de ítems en el carrito
  final Map<int, CartItem> _items = {};

  // Forma pública de obtener los ítems
  List<CartItem> get items => _items.values.toList();

  // Obtener el número total de productos (sumando cantidades)
  int get totalItemCount {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  // Obtener el precio total
  double get totalPrice {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  /// Método para AÑADIR un producto al carrito
  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      // Si el producto ya está en el carrito, solo incrementa la cantidad
      _items[product.id]!.increment();
    } else {
      // Si es un producto nuevo, lo añade al mapa
      _items[product.id] = CartItem(product: product, quantity: 1);
    }

    // Notifica a todos los widgets que están "escuchando" que el carrito cambió
    notifyListeners();
  }

  /// Método para REMOVER un producto del carrito
  void removeFromCart(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// Método para VACIAR el carrito (ej. después de una compra)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
