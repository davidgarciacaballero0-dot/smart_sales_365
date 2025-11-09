// lib/screens/catalog_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package_wrapper.dart'; // Importa el wrapper

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/product_service.dart';
import 'package:smartsales365/widgets/product_card.dart';
import 'package:smartsales365/widgets/product_filter_drawer.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ProductService _productService = ProductService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Futuro para la carga inicial de datos (productos y filtros)
  late Future<Map<String, dynamic>> _initialDataFuture;

  // Estado de los filtros y búsqueda
  Map<String, dynamic> _currentFilters = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Carga los datos iniciales
    _initialDataFuture = _loadInitialData();
  }

  /// Carga los productos y los datos para los filtros (marcas/categorías)
  Future<Map<String, dynamic>> _loadInitialData() async {
    try {
      // Usamos el token para la lógica de "Mis Reseñas" en el ProductService
      // CORRECCIÓN 1/1:
      // Cambiado de 'accessToken' a 'token'
      final String? token = context.read<AuthProvider>().token;

      // Pasamos los filtros y el token al servicio
      final products = await _productService.getProducts(
        filters: _currentFilters,
        token: token,
      );

      // (En una implementación real, aquí también cargaríamos las marcas y categorías
      // para pasárselas al ProductFilterDrawer. Por ahora, el drawer las carga
      // por sí mismo, lo cual está bien).

      return {'products': products};
    } catch (e) {
      rethrow;
    }
  }

  /// Vuelve a cargar los datos (generalmente después de aplicar filtros)
  void _reloadData() {
    setState(() {
      _initialDataFuture = _loadInitialData();
    });
  }

  /// Maneja la aplicación de filtros desde el Drawer
  void _onApplyFilters(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
      // Combina la búsqueda con los filtros
      _currentFilters['search'] = _searchQuery;
    });
    _reloadData();
    Navigator.of(context).pop(); // Cierra el drawer
  }

  /// Maneja el cambio en la barra de búsqueda
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentFilters['search'] = query;
    });
    // Opcional: podrías añadir un debounce (retraso) aquí
    _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Asigna la key al Scaffold
      appBar: _buildAppBar(),
      drawer: ProductFilterDrawer(
        onApplyFilters: _onApplyFilters,
        initialFilters: _currentFilters,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar productos: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!['products'].isEmpty) {
            return const Center(child: Text('No se encontraron productos.'));
          }

          final List<Product> products = snapshot.data!['products'];
          return _buildProductGrid(products);
        },
      ),
    );
  }

  /// Construye el AppBar con la barra de búsqueda y el botón de filtro
  AppBar _buildAppBar() {
    return AppBar(
      title: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Abre el Drawer (el menú lateral de filtros)
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ],
      backgroundColor: Colors.grey[100],
      elevation: 0,
    );
  }

  /// Construye la cuadrícula de productos
  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.75, // Ajusta esto para el tamaño de la tarjeta
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
