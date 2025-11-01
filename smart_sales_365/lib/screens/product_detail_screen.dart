// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/models/review_model.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';
import 'package:smart_sales_365/services/product_service.dart';
import 'package:smart_sales_365/widgets/cart_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  // --- CORRECCIÓN: Constructor actualizado a 'const super.key' ---
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<List<Review>> _reviewsFuture;
  final ProductService _productService = ProductService();

  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _userRating = 3.0; // Calificación por defecto

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    setState(() {
      _reviewsFuture = _productService.getReviews(widget.product.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showReviewForm(BuildContext context) {
    _userRating = 3.0;
    _commentController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        bool isPostingInModal = false; // Estado local para el botón de carga

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Escribe tu opinión',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: RatingBar.builder(
                          initialRating: _userRating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) =>
                              Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {
                            _userRating = rating;
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          labelText: 'Comentario',
                          hintText: 'Describe tu experiencia...',
                        ),
                        maxLines: 3,
                        validator: (value) => value!.isEmpty
                            ? 'Por favor ingresa un comentario'
                            : null,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isPostingInModal
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setModalState(() {
                                    isPostingInModal = true;
                                  });

                                  // --- CORRECCIÓN: Guardar el BuildContext ---
                                  final navigator = Navigator.of(context);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );

                                  try {
                                    await _productService.postReview(
                                      productId: widget.product.id,
                                      rating: _userRating,
                                      comment: _commentController.text,
                                    );

                                    navigator.pop(); // Cierra el modal
                                    _loadReviews(); // Recarga la lista de reseñas

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '¡Gracias por tu opinión!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error: ${e.toString().replaceFirst("Exception: ", "")}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    // --- CORRECCIÓN: mounted check ---
                                    if (mounted) {
                                      setModalState(() {
                                        isPostingInModal = false;
                                      });
                                    }
                                  }
                                }
                              },
                        child: isPostingInModal
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text('Publicar Opinión'),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        // --- CORRECCIÓN: Eliminado 'const' de la lista ---
        actions: [const CartBadge()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReviewForm(context),
        icon: Icon(Icons.rate_review_outlined),
        label: Text('Opinar'),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              // --- CORRECCIÓN: Usar SizedBox en lugar de Container ---
              height: 300,
              width: double.infinity,
              child: Image.network(
                // --- CORRECCIÓN: Usar el '??' con el modelo nullable ---
                widget.product.image ?? 'https://via.placeholder.com/300',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 100,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\$${widget.product.price}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.product.description ??
                        'No hay descripción disponible.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add_shopping_cart),
                    label: Text('Añadir al Carrito'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    onPressed: () {
                      // --- CORRECCIÓN: Pasar el objeto 'product' ---
                      Provider.of<CartProvider>(
                        context,
                        listen: false,
                      ).addItem(widget.product);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${widget.product.name} añadido al carrito!',
                          ),
                          duration: Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'DESHACER',
                            onPressed: () {
                              // --- CORRECCIÓN: Usar el método correcto ---
                              Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).removeSingleItem(widget.product.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Categoría: ${widget.product.categoryName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Marca: ${widget.product.brandName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Stock: ${widget.product.stock}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            Divider(height: 30, thickness: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Opiniones de Clientes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),

            FutureBuilder<List<Review>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar reseñas: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Este producto aún no tiene opiniones. ¡Sé el primero!',
                      ),
                    ),
                  );
                }

                final reviews = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (ctx, index) {
                    final review = reviews[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          review.user,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(review.comment),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          child: Text(review.rating.toStringAsFixed(1)),
                        ),
                        trailing: RatingBarIndicator(
                          rating: review.rating,
                          itemBuilder: (context, index) =>
                              Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 16.0,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
