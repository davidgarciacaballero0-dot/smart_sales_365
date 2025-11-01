// lib/widgets/cart_item_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/models/cart_item_model.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final int productId;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 40,
        ),
      ),
      onDismissed: (direction) {
        cart.removeItem(productId);
      },
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Estás seguro?'),
            content: const Text(
              '¿Quieres eliminar este producto del carrito?',
            ),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
              ),
              TextButton(
                child: const Text('Sí'),
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FittedBox(
                  child: Text('\$${item.productDetails.price}'),
                ),
              ),
            ),
            title: Text(item.productDetails.name),
            subtitle: Text('Total: \$${item.subtotal.toStringAsFixed(2)}'),
            trailing: Text('${item.quantity} x'),
          ),
        ),
      ),
    );
  }
}
