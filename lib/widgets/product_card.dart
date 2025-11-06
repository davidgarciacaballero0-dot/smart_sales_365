// lib/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/product_model.dart'; // Importamos nuestro modelo

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Usamos Card para darle un borde bonito y elevación
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias, // Recorta la imagen para que se ajuste
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. IMAGEN ---
          Expanded(
            child: Container(
              color: Colors.grey[200], // Un fondo mientras carga la imagen
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
                  maxLines: 2, // Máximo 2 líneas para el nombre
                  overflow: TextOverflow.ellipsis, // Pone '...' si es muy largo
                ),
                const SizedBox(height: 4),
                // Precio del producto
                Text(
                  // Usamos 'toStringAsFixed(2)' para mostrar 2 decimales
                  // y 'Bs.' como moneda (puedes cambiarlo a '$' o lo que necesites)
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
    );
  }

  // Método privado para construir la imagen
  Widget _buildProductImage() {
    // Tu serializador devuelve una URL completa si la imagen existe
    final imageUrl = product.image;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Usamos Image.network para cargar imágenes desde una URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover, // Cubre todo el espacio disponible
        // Muestra un indicador de carga mientras la imagen baja
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        // Muestra un ícono de error si la imagen falla al cargar
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
        },
      );
    } else {
      // Si el producto no tiene imagen, muestra un ícono genérico
      return const Icon(Icons.shopping_bag, size: 40, color: Colors.grey);
    }
  }
}
