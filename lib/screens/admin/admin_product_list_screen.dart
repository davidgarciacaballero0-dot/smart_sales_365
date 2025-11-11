// lib/screens/admin/admin_product_list_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/models/products_response_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/admin/admin_product_form_screen.dart';
import 'package:smartsales365/services/product_service.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final ProductService _productService = ProductService();
  late Future<ProductsResponse> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  /// Carga o recarga la lista de productos
  void _fetchProducts() {
    setState(() {
      // Llama al servicio para obtener productos.
      // A diferencia del CRUD de marcas/categorías, este no requiere token
      // porque es el mismo endpoint que usa el cliente.
      _productsFuture = _productService.getProducts(token: '');
    });
  }

  /// Navega al formulario para crear o editar un producto
  Future<void> _navigateToForm({Product? product}) async {
    // Navega a la pantalla del formulario
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminProductFormScreen(product: product),
      ),
    );

    // Si el formulario regresó 'true', significa que se guardó algo
    // y debemos refrescar la lista.
    if (result == true) {
      _fetchProducts();
    }
  }

  /// Muestra diálogo de confirmación y elimina un producto
  Future<void> _deleteProduct(int productId) async {
    final bool didConfirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar este producto?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (didConfirm && mounted) {
      // CORRECCIÓN 1/1:
      // Cambiado de 'accessToken' a 'token' para que coincida con tu AuthProvider
      final String? token = context.read<AuthProvider>().token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No autorizado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await _productService.deleteProduct(token, productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProducts(); // Refresca la lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Productos'),
        actions: [
          // Botón para refrescar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
          // Botón para crear nuevo producto
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: FutureBuilder<ProductsResponse>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final productsResponse = snapshot.data;
          if (productsResponse == null || productsResponse.products.isEmpty) {
            return const Center(child: Text('No se encontraron productos.'));
          }
          return _buildProductListView(productsResponse.products);
        },
      ),
    );
  }

  /// Widget que construye la lista de productos
  Widget _buildProductListView(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: product.image != null
                ? Image.network(
                    product.image!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    // Manejo de error si la imagen no carga
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 50),
                  )
                : const Icon(Icons.shopping_bag, size: 50),
            title: Text(product.name),
            subtitle: Text(
              'Bs. ${product.price.toStringAsFixed(2)} - Stock: ${product.stock}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Editar
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueGrey[700]),
                  onPressed: () => _navigateToForm(product: product),
                ),
                // Botón Eliminar
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteProduct(product.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
