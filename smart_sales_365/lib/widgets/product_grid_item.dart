// lib/widgets/product_grid_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/screens/product_detail_screen.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;

  const ProductGridItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usamos 'Provider.of' sin 'listen: false' aquí
    final cart = Provider.of<CartProvider>(context, listen: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: GridTile(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ProductDetailScreen(product: product),
              ),
            );
          },
          child: Image.network(
            product.image ??
                'https://via.placeholder.com/150', // Imagen por defecto
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              );
            },
          ),
        ),
        footer: GridTileBar(
          backgroundColor: Colors.black87,
          title: Text(
            product.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          subtitle: Text(
            '\$${product.price}', // Mostrar precio
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            icon: Icon(Icons.add_shopping_cart),
            onPressed: () {
              // --- MODIFICACIÓN: Pasamos el objeto 'product' completo ---
              cart.addItem(product);

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} añadido al carrito!'),
                  duration: Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'DESHACER',
                    onPressed: () {
                      // --- MODIFICACIÓN: Usamos el método que sí existe ---
                      cart.removeSingleItem(product.id);
                    },
                  ),
                ),
              );
            },
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
        ),
      ),
    );
  }
}
