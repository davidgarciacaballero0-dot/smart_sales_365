// lib/widgets/product_grid_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/screens/product_detail_screen.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;

  const ProductGridItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: GridTile(
        footer: GridTileBar(
          backgroundColor: Colors.black87,
          title: Text(
            product.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12), // <-- CONST AÑADIDO
          ),
          subtitle: Text(
            '\$${product.price}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                // <-- CONST AÑADIDO
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart), // <-- CONST AÑADIDO
            onPressed: () {
              cart.addItem(product);

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} añadido al carrito!'),
                  duration: const Duration(seconds: 2), // <-- CONST AÑADIDO
                  action: SnackBarAction(
                    label: 'DESHACER',
                    onPressed: () {
                      cart.removeSingleItem(product.id);
                    },
                  ),
                ),
              );
            },
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ProductDetailScreen(product: product),
              ),
            );
          },
          child: Image.network(
            product.image ?? 'https://via.placeholder.com/150',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              );
            },
          ),
        ),
      ),
    );
  }
}
