// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/providers/product_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  // Nombre de la ruta para la navegación
  static const String routeName = '/product-detail';

  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Obtenemos el ID del producto pasado como argumento al navegar
    final productId = ModalRoute.of(context)?.settings.arguments as int?;

    // Si no se pasó un ID (esto no debería ocurrir con la navegación correcta)
    if (productId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    // Buscamos el producto en la lista del Provider usando el ID
    // Usamos context.select para escuchar solo cambios en el producto específico
    // o si la lista de productos cambia por completo.
    final Product? product = context.select<ProductProvider, Product?>(
      (provider) => provider.findProductById(productId),
    );

    // Si el producto no se encuentra en el provider (raro si la navegación es correcta)
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Producto con ID $productId no encontrado')),
      );
    }

    // --- Construcción de la UI de Detalle ---
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name), // Título con el nombre del producto
      ),
      body: SingleChildScrollView(
        // Para permitir scroll si el contenido es largo
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Imagen ---
            Container(
              height: 300, // Altura fija para la imagen
              color: Colors.grey[200],
              child: product.image != null
                  ? Image.network(
                      product.image!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // --- Información del Producto (Padding alrededor) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Nombre del Producto ---
                  Text(
                    product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Precio ---
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Descripción ---
                  Text(
                    'Descripción',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'No disponible.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  // --- Stock ---
                  Row(
                    children: [
                      Icon(Icons.inventory, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Stock disponible: ${product.stock}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          // Color verde si hay stock, rojo si no
                          color: product.stock > 0
                              ? Colors.green.shade700
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- Categoría y Marca ---
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Categoría: ${product.categoryName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.label_outline,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Marca: ${product.brandName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Botón Añadir al Carrito (Placeholder Fase 3) ---
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Añadir al Carrito'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                      // Deshabilitado si no hay stock
                      onPressed: product.stock > 0
                          ? () {
                              // TODO: Implementar lógica del carrito en Fase 3
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} añadido al carrito (¡Próximamente!)',
                                  ),
                                ),
                              );
                            }
                          : null, // null deshabilita el botón
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
