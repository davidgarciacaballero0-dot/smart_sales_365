// lib/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/product_model.dart';
// 1. Importa la nueva pantalla de detalle
import 'package:smartsales365/screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // 2. Envuelve el Card en un 'InkWell' para hacerlo clicable
    return InkWell(
      onTap: () {
        // 3. Acción al tocar: Navegar a la pantalla de detalle
        Navigator.push(
          context,
          MaterialPageRoute(
            // 4. Le pasamos el ID del producto a la nueva pantalla
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. IMAGEN ---
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: _buildProductImage(),
              ),
            ),

            // --- 2. INFORMACIÓN (Nombre y Precio) ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del producto
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Precio del producto
                  Text(
                    'Bs. ${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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

  // ... (El método _buildProductImage queda exactamente igual) ...
  Widget _buildProductImage() {
    final imageUrl = product.image;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    } else {
      return const Icon(Icons.shopping_bag, size: 40, color: Colors.grey);
    }
  }
}
