// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/providers/product_provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart'; // <--- 1. Importar CartProvider

class ProductDetailScreen extends StatelessWidget {
  static const String routeName = '/product-detail';

  const ProductDetailScreen({super.key});

  // --- 2. Crear función para manejar la adición al carrito ---
  Future<void> _addItemToCart(BuildContext context, Product product) async {
    final cartProvider = context.read<CartProvider>();
    try {
      // Llama al provider
      final success = await cartProvider.addItem(product.id);

      if (!context.mounted) return; // Comprobar si el widget sigue montado

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} añadido al carrito.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Mostrar error si el provider devuelve false
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cartProvider.errorMessage.isNotEmpty
                  ? cartProvider.errorMessage
                  : 'Error al añadir al carrito.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Captura por si acaso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productId = ModalRoute.of(context)?.settings.arguments as int?;

    if (productId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Producto no encontrado')),
      );
    }

    // Escuchamos ProductProvider
    final Product? product = context.select<ProductProvider, Product?>(
      (provider) => provider.findProductById(productId),
    );

    // --- 3. Escuchamos el estado de carga del CartProvider ---
    final bool isCartLoading = context.watch<CartProvider>().isLoading;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Producto con ID $productId no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        // TODO: Añadiremos el ícono del carrito aquí
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... (Imagen, Nombre, Precio, Descripción, etc. sin cambios) ...
            Container(
              height: 300,
              color: Colors.grey[200],
              child: product.image != null
                  ? Image.network(
                      product.image!,
                      fit: BoxFit.cover,
                      // ... (loadingBuilder y errorBuilder) ...
                    )
                  : const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  Row(
                    children: [
                      Icon(Icons.inventory, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Stock disponible: ${product.stock}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: product.stock > 0
                              ? Colors.green.shade700
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                      // Usamos el getter 'brandName' que creamos
                      Text(
                        'Marca: ${product.brandName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- 4. Conexión del Botón ---
                  Center(
                    // Si el carrito está ocupado, muestra un indicador
                    child: isCartLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Añadir al Carrito'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              textStyle: theme.textTheme.titleMedium,
                            ),
                            // Deshabilitado si no hay stock O si ya está cargando
                            onPressed: product.stock > 0
                                ? () => _addItemToCart(context, product)
                                : null,
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
