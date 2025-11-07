// lib/screens/product_detail_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importa Provider
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/cart_provider.dart'; // 2. Importa el CartProvider
import 'package:smartsales365/services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _productFuture;
  final ProductService _productService = ProductService();
  Product? _product; // Guardaremos el producto aquí cuando cargue

  @override
  void initState() {
    super.initState();
    _productFuture = _productService.getProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),

      // 3. AÑADIMOS UN BOTÓN FIJO EN LA PARTE INFERIOR
      // Se mostrará solo si el producto cargó exitosamente
      bottomNavigationBar: _product != null
          ? _buildBottomBar(context, _product!)
          : null,

      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el producto:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            // 4. CUANDO EL PRODUCTO CARGA, LO GUARDAMOS EN EL ESTADO
            // Esto permite que el 'bottomNavigationBar' se dibuje
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _product = snapshot.data!;
                });
              }
            });

            final product = snapshot.data!;
            return SingleChildScrollView(
              // 5. Añadimos padding en la parte inferior para que el
              //    botón fijo no tape el contenido
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProductImage(product.image),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bs. ${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildWarrantyInfo(product),
                        const SizedBox(height: 24),
                        Text(
                          'Descripción',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description ??
                              'No hay descripción disponible.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Producto no encontrado.'));
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Sin cambios) ---
  Widget _buildProductImage(String? imageUrl) {
    // ... (código idéntico al de la respuesta anterior) ...
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
          );
        },
      );
    } else {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Icon(Icons.shopping_bag, size: 60, color: Colors.grey),
      );
    }
  }

  Widget _buildWarrantyInfo(Product product) {
    // ... (código idéntico al de la respuesta anterior) ...
    final brand = product.brand;
    final warrantyMonths = brand?.warrantyDurationMonths;

    if (warrantyMonths != null && warrantyMonths > 0) {
      return Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.black54, size: 20),
          const SizedBox(width: 8),
          Text(
            'Garantía: $warrantyMonths meses',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // 6. ¡NUEVO WIDGET PARA EL BOTÓN!
  Widget _buildBottomBar(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 16, // Para safe area
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blueGrey[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          // 7. USA EL PROVIDER PARA AÑADIR AL CARRITO
          final cart = context.read<CartProvider>();
          cart.addToCart(product);

          // 8. MUESTRA UNA NOTIFICACIÓN
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡"${product.name}" añadido al carrito!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: const Text(
          'Añadir al Carrito',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
