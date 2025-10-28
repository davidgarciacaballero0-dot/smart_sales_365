// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';
import 'package:smart_sales_365/providers/product_provider.dart'; // Importa ProductProvider
import 'package:smart_sales_365/widgets/product_grid_item.dart'; // Importa el item

// Convertimos HomeScreen a StatefulWidget para poder llamar a loadProducts() una vez
class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variable para asegurar que loadProducts() se llame solo una vez
  bool _isInit = true;
  bool _isLoadingProducts = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Llamamos a loadProducts aquí, asegurándonos que solo se ejecute una vez
    if (_isInit) {
      setState(() {
        _isLoadingProducts = true;
      });
      // Usamos context.read() porque estamos dentro de un método
      // que no es build() y no necesitamos escuchar cambios aquí.
      context.read<ProductProvider>().loadProducts().then((_) {
        // Cuando termina la carga (éxito o error), actualizamos el estado local
        if (mounted) {
          // Verifica si el widget todavía está montado
          setState(() {
            _isLoadingProducts = false;
          });
        }
      });
      _isInit = false; // Marcamos como inicializado
    }
  }

  // Función para reintentar la carga si hubo error
  Future<void> _refreshProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });
    await context.read<ProductProvider>().loadProducts();
    if (mounted) {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios en ProductProvider usando Consumer
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Muestra loading inicial
          : Consumer<ProductProvider>(
              // Escucha cambios en ProductProvider
              builder: (context, productProvider, child) {
                // --- Caso 1: Error al cargar ---
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
                          onPressed:
                              _refreshProducts, // Llama a la función de reintento
                        ),
                      ],
                    ),
                  );
                }

                // --- Caso 2: Productos cargados ---
                if (productProvider.status == ProductStatus.loaded) {
                  // Si la lista está vacía
                  if (productProvider.products.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay productos disponibles.',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }
                  // Si hay productos, los mostramos en un GridView
                  return GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: productProvider.products.length,
                    // Define cómo se ve cada item en la cuadrícula
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 columnas
                          childAspectRatio:
                              2 / 3, // Proporción ancho/alto de cada item
                          crossAxisSpacing: 10, // Espacio horizontal
                          mainAxisSpacing: 10, // Espacio vertical
                        ),
                    itemBuilder: (ctx, i) =>
                        ProductGridItem(product: productProvider.products[i]),
                  );
                }

                // --- Caso 3: Cargando (después del loading inicial) o Idle ---
                // Esto podría mostrarse brevemente si se hace un refresh manual
                return const Center(child: CircularProgressIndicator());
              },
            ),
    );
  }
}
