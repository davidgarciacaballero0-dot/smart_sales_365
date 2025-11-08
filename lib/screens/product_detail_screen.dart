// lib/screens/product_detail_screen.dart

// ignore_for_file: unused_import, deprecated_member_use, no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/providers/tab_provider.dart'; // 1. Importa el TabProvider
import 'package:smartsales365/services/product_service.dart';
// ... (otros imports como review_model, auth_provider, rating_bar, intl)
import 'package:smartsales365/models/review_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _productFuture;
  final ProductService _productService = ProductService();
  Product? _product;

  @override
  void initState() {
    super.initState();
    // ¡USA EL product_service ACTUALIZADO!
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _product = snapshot.data!;
                });
              }
            });
            final product = snapshot.data!;
            return SingleChildScrollView(
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
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Reseñas de Clientes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _ProductReviewsSection(productId: product.id),
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

  // --- WIDGET AUXILIAR DEL BOTÓN (ACTUALIZADO) ---
  Widget _buildBottomBar(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
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
          // 2. LEE AMBOS PROVIDERS
          final cart = context.read<CartProvider>();
          final tab = context.read<TabProvider>();

          // 3. AÑADE AL CARRITO
          cart.addToCart(product);

          // 4. (Opcional) Muestra la notificación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡"${product.name}" añadido al carrito!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );

          // 5. CAMBIA LA PESTAÑA A "CARRITO" (índice 1)
          tab.changeTab(1);

          // 6. CIERRA LA PANTALLA DE DETALLE
          Navigator.of(context).pop();
        },
        child: const Text(
          'Añadir al Carrito e Ir', // Texto actualizado
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Imagen y Garantía) ---
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
    return const SizedBox.shrink();
  }
}

// --- WIDGET INTERNO DE RESEÑAS ---
class _ProductReviewsSection extends StatefulWidget {
  final int productId;
  const _ProductReviewsSection({required this.productId});

  @override
  State<_ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<_ProductReviewsSection> {
  final ProductService _productService = ProductService();
  late Future<List<Review>> _reviewsFuture;
  bool _isPostingReview = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  void _fetchReviews() {
    setState(() {
      _reviewsFuture = _productService.getReviews(widget.productId);
    });
  }

  void _showReviewDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para dejar una reseña.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double _rating = 3.0;
    final _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escribe tu Reseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  _rating = rating;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: _isPostingReview
                  ? null
                  : () async {
                      setState(() {
                        _isPostingReview = true;
                      });
                      try {
                        await _productService.postReview(
                          token: authProvider.accessToken!,
                          productId: widget.productId,
                          rating: _rating,
                          comment: _commentController.text,
                        );

                        Navigator.of(context).pop();
                        _fetchReviews();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Reseña publicada!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isPostingReview = false;
                        });
                      }
                    },
              child: _isPostingReview
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated =
        context.watch<AuthProvider>().status == AuthStatus.authenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAuthenticated)
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Escribir una reseña'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[50],
              foregroundColor: Colors.blueGrey[800],
              elevation: 0,
            ),
            onPressed: () => _showReviewDialog(context),
          ),

        const SizedBox(height: 16),

        FutureBuilder<List<Review>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar reseñas: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Sé el primero en dejar una reseña.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            final reviews = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  elevation: 0,
                  color: Colors.grey[100],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.user,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              // Usando el 'getter' del modelo
                              review.formattedDate,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RatingBarIndicator(
                          rating: review.rating.toDouble(),
                          itemBuilder: (context, index) =>
                              const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 16.0,
                        ),
                        if (review.comment != null &&
                            review.comment!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(review.comment!),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
