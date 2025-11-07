// lib/models/cart_item_model.dart

// Importa el modelo de producto que ya teníamos
import 'package:smartsales365/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Función para incrementar la cantidad
  void increment() {
    quantity++;
  }
}
