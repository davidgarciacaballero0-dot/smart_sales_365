// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:smart_sales_365/models/cart_item_model.dart';
import 'package:smart_sales_365/models/product_model.dart';
// No necesitamos el 'cart_service.dart' aquí, el provider maneja la lógica local.
// import 'package:smart_sales_365/services/cart_service.dart';

class CartProvider with ChangeNotifier {
  Map<int, CartItem> _items = {};

  Map<int, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    // Devuelve el número de productos únicos en el carrito
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      // --- CORRECCIÓN: ---
      // Usamos el 'subtotal' de tu CartItem, que ya está calculado
      total += cartItem.subtotal;
      // --- FIN DE LA CORRECCIÓN ---
    });
    return total;
  }

  // --- MÉTODO MODIFICADO (para que coincida con el código que te di) ---
  /// Añade un producto al carrito. Si ya existe, incrementa la cantidad.
  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      // --- CORRECCIÓN: Usa el constructor correcto de CartItem ---
      _items.update(
        product.id,
        (existingItem) => CartItem(
          id: existingItem.id, // Reutiliza el ID del item
          quantity: existingItem.quantity + 1,
          subtotal:
              (existingItem.quantity + 1) *
              product.price, // Calcula el nuevo subtotal
          productDetails: existingItem.productDetails, // Reutiliza los detalles
        ),
      );
      // --- FIN DE LA CORRECCIÓN ---
    } else {
      // --- CORRECCIÓN: Usa el constructor correcto de CartItem ---
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: product.id, // Usa el ID del producto como ID del item
          quantity: 1,
          subtotal: product.price, // El subtotal inicial es el precio
          productDetails: product, // Almacena el objeto Product completo
        ),
      );
      // --- FIN DE LA CORRECCIÓN ---
    }
    notifyListeners();
  }

  /// Elimina un producto (y todas sus cantidades) del carrito.
  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // --- MÉTODO NUEVO AÑADIDO (necesario para la UI que te envié) ---
  /// Reduce la cantidad de un item. Si la cantidad llega a 0, lo elimina.
  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      // --- CORRECCIÓN: Usa el constructor correcto de CartItem ---
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          quantity: existingItem.quantity - 1,
          subtotal:
              (existingItem.quantity - 1) *
              existingItem.productDetails.price, // Calcula el nuevo subtotal
          productDetails: existingItem.productDetails,
        ),
      );
      // --- FIN DE LA CORRECCIÓN ---
    } else {
      // Si solo hay 1, elimina el producto del carrito
      _items.remove(productId);
    }
    notifyListeners();
  }

  /// Limpia todo el carrito.
  void clearCart() {
    _items = {};
    notifyListeners();
  }
}
