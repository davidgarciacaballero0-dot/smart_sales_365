// lib/widgets/product_grid_item.dart
import 'package:flutter/material.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/screens/product_detail_screen.dart'; // Importa la pantalla de detalle

class ProductGridItem extends StatelessWidget {
  final Product product;

  const ProductGridItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      // Envolvemos todo en InkWell para hacerlo tappable
      child: InkWell(
        onTap: () {
          // Navegamos a la pantalla de detalle al tocar
          Navigator.of(context).pushNamed(
            ProductDetailScreen.routeName,
            arguments: product.id, // Pasamos el ID del producto como argumento
          );
        },
        child: Column(
          // El contenido del Card sigue igual
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Imagen del Producto ---
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: product.image != null
                    ? Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),

            // --- Nombre y Precio ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
