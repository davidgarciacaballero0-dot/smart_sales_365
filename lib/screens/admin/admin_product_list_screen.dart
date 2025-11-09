// lib/screens/admin/admin_product_list_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/product_service.dart';
// 1. IMPORTA LA NUEVA PANTALLA DE FORMULARIO
import 'package:smartsales365/screens/admin/admin_product_form_screen.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() {
    setState(() {
      _productsFuture = _productService.getProducts(token: '');
    });
  }

  /// Navega al formulario (para crear o editar)
  Future<void> _navigateToForm({Product? product}) async {
    // 2. Navega al formulario y ESPERA una respuesta
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminProductFormScreen(product: product),
      ),
    );

    // 3. Si el formulario devolvió 'true' (o sea, si se guardó algo),
    //    refresca la lista de productos.
    if (result == true) {
      _fetchProducts();
    }
  }

  /// Maneja la eliminación de un producto
  Future<void> _deleteProduct(int productId) async {
    final bool didConfirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.',
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
      final String? token = context.read<AuthProvider>().accessToken;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Token no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await _productService.deleteProduct(token, productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchProducts();
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
          // 4. Conecta el botón "Añadir"
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Añadir Producto',
            onPressed: () {
              // Llama a la navegación sin producto (modo "Crear")
              _navigateToForm();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar productos:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay productos.'));
          }

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (product.image != null)
                      ? NetworkImage(product.image!)
                      : null,
                  child: (product.image == null)
                      ? const Icon(Icons.inventory_2)
                      : null,
                ),
                title: Text(product.name),
                subtitle: Text(
                  'Stock: ${product.stock} | Precio: Bs. ${product.price}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 5. Conecta el botón "Editar"
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueGrey[700]),
                      onPressed: () {
                        // Llama a la navegación CON producto (modo "Editar")
                        _navigateToForm(product: product);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteProduct(product.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
