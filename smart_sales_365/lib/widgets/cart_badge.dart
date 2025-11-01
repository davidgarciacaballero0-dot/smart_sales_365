// lib/widgets/cart_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';

// import 'package:smart_sales_365/screens/cart_screen.dart';

class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (ctx, cart, ch) => Badge(
        label: Text(cart.itemCount.toString()),
        isLabelVisible: cart.itemCount > 0,
        child: ch,
      ),
      child: IconButton(
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: () {
          // --- CORRECCIÓN LINTER: 'TODO' eliminado ---
          // Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => CartScreen()));

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aquí se abrirá la pantalla del Carrito (Fase 3)'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
