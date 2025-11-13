// lib/screens/product_detail_screen.dart

// ignore_for_file: unused_import, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/providers/tab_provider.dart';
import 'package:smartsales365/services/product_service.dart';
import 'package:smartsales365/models/review_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/utils/error_handler.dart';
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
    // Obtener token directamente en initState sin doble fetch
    final String? token = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).token;
    _productFuture = _productService.getProductById(
      widget.productId,
      token: token,
    );
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
            final errorMsg = ErrorHandler.getErrorMessage(snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _productFuture = _productService.getProductById(
                            widget.productId,
                          );
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _product != snapshot.data) {
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
                          product.description,
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
                        _ProductReviewsSection(
                          productId: product.id,
                          hasReviewed:
                              false, // TODO: Implementar lógica desde backend
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
        onPressed: () async {
          final cart = context.read<CartProvider>();
          final auth = context.read<AuthProvider>();
          final tab = context.read<TabProvider>();

          // Verificar autenticación
          if (auth.token == null) {
            ErrorHandler.showInfo(
              context,
              'Debes iniciar sesión para añadir al carrito',
            );
            return;
          }

          // Añadir al carrito (backend)
          final success = await cart.addToCart(
            token: auth.token!,
            productId: product.id,
            quantity: 1,
          );

          if (success) {
            ErrorHandler.showSuccess(
              context,
              '¡"${product.name}" añadido al carrito!',
            );

            tab.changeTab(1);
            Navigator.of(context).pop();
          } else {
            ErrorHandler.showError(
              context,
              cart.errorMessage ?? 'Error desconocido',
              prefix: 'Error al añadir al carrito',
            );
          }
        },
        child: const Text(
          'Añadir al Carrito e Ir',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

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
    final warrantyMonths = product.warrantyDurationMonths;

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

class _ProductReviewsSection extends StatefulWidget {
  final int productId;
  final bool hasReviewed;

  const _ProductReviewsSection({
    required this.productId,
    required this.hasReviewed,
  });

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

    double rating = 3.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Escribe tu Reseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RatingBar.builder(
                    initialRating: rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (newRating) {
                      setDialogState(() {
                        rating = newRating;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
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
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                              token: authProvider.token!,
                              productId: widget.productId,
                              rating: rating,
                              comment: commentController.text,
                            );

                            Navigator.of(dialogContext).pop();
                            _fetchReviews();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Reseña publicada!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.of(dialogContext).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isPostingReview = false;
                              });
                            }
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            bool canReview =
                auth.status == AuthStatus.authenticated && !widget.hasReviewed;

            if (canReview) {
              return ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Escribir una reseña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[50],
                  foregroundColor: Colors.blueGrey[800],
                  elevation: 0,
                ),
                onPressed: () => _showReviewDialog(context),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
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
                        Text(
                          review.user,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RatingBarIndicator(
                              rating: review.rating.toDouble(),
                              itemBuilder: (context, index) =>
                                  const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 16.0,
                            ),
                            Text(
                              review.formattedDate,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
