// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';
import 'package:smart_sales_365/providers/product_provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart'; // <--- 1. Importar CartProvider
import 'package:smart_sales_365/widgets/product_grid_item.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInit = true;
  bool _isLoadingProducts = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      setState(() {
        _isLoadingProducts = true;
      });

      // Cargamos tanto productos como el carrito
      Future.wait([
        context.read<ProductProvider>().loadProducts(),
        context.read<CartProvider>().loadCart(), // <--- 2. Llamar a loadCart()
      ]).then((_) {
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
          });
        }
      });
      _isInit = false;
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });
    // Al refrescar, también recargamos ambos
    await Future.wait([
      context.read<ProductProvider>().loadProducts(),
      context
          .read<CartProvider>()
          .loadCart(), // <--- 3. Añadir loadCart() al refresh
    ]);
    if (mounted) {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          // TODO: Añadiremos el ícono del carrito aquí
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              // <--- 4. Limpiar carrito ANTES de hacer logout ---
              context.read<CartProvider>().clearLocalCart();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                // ... (El resto del widget Consumer sigue igual) ...
                if (productProvider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar productos:',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productProvider.errorMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          onPressed: _refreshProducts,
                        ),
                      ],
                    ),
                  );
                }

                if (productProvider.status == ProductStatus.loaded) {
                  if (productProvider.products.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay productos disponibles.',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: productProvider.products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: (ctx, i) =>
                        ProductGridItem(product: productProvider.products[i]),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
    );
  }
}
