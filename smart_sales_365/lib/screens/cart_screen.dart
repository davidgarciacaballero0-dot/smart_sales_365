// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // Definimos la ruta estática para main.dart
  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    // Escuchamos al CartProvider
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
      ),
      body: Column(
        children: [
          // 1. La Lista de Items
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: Text('Tu carrito está vacío.',
                        style: TextStyle(fontSize: 18)),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (ctx, index) {
                      final item = cartItems[index];
                      // Usamos Dismissible para permitir "deslizar para borrar"
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) {
                          // Llama al provider para eliminar el item
                          Provider.of<CartProvider>(context, listen: false)
                              .removeItem(item.id);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${item.productDetails.name} eliminado del carrito.'),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: FittedBox(
                                  child: Text('\$${item.productDetails.price}'),
                                ),
                              ),
                            ),
                            title: Text(item.productDetails.name),
                            subtitle: Text(
                                'Total: \$${item.subtotal.toStringAsFixed(2)}'),
                            trailing: Text('${item.quantity} x'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // 2. El Resumen y Botón de Pago
          if (cartItems.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(15),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 20)),
                        Chip(
                          label: Text(
                            '\$${cart.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .titleLarge
                                  ?.color,
                            ),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implementar lógica de pago (Stripe) en la siguiente tarea
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Aquí inicia el proceso de pago con Stripe (Fase 3)'),
                          ),
                        );
                      },
                      child: const Text('IR A PAGAR'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
