// lib/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  // 1. Recibimos el ID del producto que queremos mostrar
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Un 'Future' para guardar el producto individual
  late Future<Product> _productFuture;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // 2. Llamamos al método getProductById usando el ID que recibimos
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
      // 3. Usamos FutureBuilder para manejar los estados de carga
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          // --- ESTADO 1: CARGANDO ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- ESTADO 2: ERROR ---
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

          // --- ESTADO 3: ÉXITO ---
          if (snapshot.hasData) {
            final product = snapshot.data!;

            // Usamos SingleChildScrollView para poder scrollear
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Imagen del Producto ---
                  _buildProductImage(product.image),

                  // --- Contenido (Nombre, Precio, Garantía, Descripción) ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Precio
                        Text(
                          'Bs. ${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // --- ¡REQUERIMIENTO CLAVE: GARANTÍA! ---
                        // 4. Mostramos la garantía (basado en el modelo de Brand)
                        _buildWarrantyInfo(product),

                        const SizedBox(height: 24),

                        // Descripción
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
                                height: 1.5, // Interlineado
                              ),
                        ),

                        // (PRÓXIMOS PASOS)
                        const SizedBox(
                          height: 100,
                        ), // Espacio para el botón de "Añadir al Carrito"
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

      // (PRÓXIMO PASO)
      // Aquí pondremos un botón flotante o fijo para "Añadir al Carrito"
    );
  }

  // Widget auxiliar para mostrar la imagen
  Widget _buildProductImage(String? imageUrl) {
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

  // Widget auxiliar para mostrar la garantía
  Widget _buildWarrantyInfo(Product product) {
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
    // Si no hay garantía, no muestra nada
    return const SizedBox.shrink();
  }
}
