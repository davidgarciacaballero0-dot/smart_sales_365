// lib/widgets/cart_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';

// (Importaremos la pantalla del carrito cuando la creemos en la Fase 3)
// import 'package:smart_sales_365/screens/cart_screen.dart';

class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos al CartProvider para obtener el número de items
    // Usamos 'Consumer' para que solo este widget se reconstruya
    return Consumer<CartProvider>(
      builder: (ctx, cart, ch) => Badge(
        // El label es el texto dentro del círculo rojo
        label: Text(cart.itemCount.toString()),
        // Solo mostramos el badge si hay items
        isLabelVisible: cart.itemCount > 0,
        // 'ch' es el child (IconButton) que no se reconstruye
        child: ch,
      ),
      child: IconButton(
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: () {
          // TODO: Navegar a CartScreen (Tarea de la Fase 3)
          // Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => CartScreen()));

          // --- Feedback temporal ---
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
