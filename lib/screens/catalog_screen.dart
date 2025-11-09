// lib/screens/catalog_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers

// CORRECCIÓN 1: Se eliminó la importación de 'package_wrapper.dart'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/product_service.dart';
import 'package:smartsales365/widgets/product_card.dart';
import 'package:smartsales365/widgets/product_filter_drawer.dart';
// CORRECCIÓN: Imports añadidos para el FilterDrawer
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';
import 'package:smartsales365/services/category_brand_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ProductService _productService = ProductService();
  // Servicio añadido para cargar datos del drawer
  final CategoryBrandService _categoryBrandService = CategoryBrandService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  late Future<Map<String, dynamic>> _initialDataFuture;

  // CORRECCIÓN: Se usa la clase ProductFilters en lugar de un Map
  ProductFilters _currentFilters = ProductFilters();
  String _searchQuery = '';

  // Getter para saber si hay filtros activos
  bool get _hasActiveFilters {
    return _currentFilters.brandId != null ||
        _currentFilters.categoryId != null ||
        _currentFilters.minPrice != null ||
        _currentFilters.maxPrice != null;
  }

  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para asegurar que el context esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialDataFuture = _loadInitialData();
    });
  }

  /// Carga productos, categorías y marcas
  Future<Map<String, dynamic>> _loadInitialData() async {
    try {
      final String? token = context.read<AuthProvider>().token;

      // CORRECCIÓN: Convertimos los filtros y la búsqueda a un Map para la API
      final Map<String, dynamic> apiFilters = {'search': _searchQuery};
      if (_currentFilters.categoryId != null) {
        apiFilters['category__id'] = _currentFilters.categoryId.toString();
      }
      if (_currentFilters.brandId != null) {
        apiFilters['brand__id'] = _currentFilters.brandId.toString();
      }
      if (_currentFilters.minPrice != null) {
        apiFilters['min_price'] = _currentFilters.minPrice.toString();
      }
      if (_currentFilters.maxPrice != null) {
        apiFilters['max_price'] = _currentFilters.maxPrice.toString();
      }
      // Limpiamos nulos o vacíos
      apiFilters.removeWhere((key, value) => value == null || value.isEmpty);

      // CORRECCIÓN: Pasamos los parámetros nombrados correctamente
      final products = await _productService.getProducts(
        token: token,
        filters: apiFilters,
      );

      // Cargamos los datos para el drawer
      final categories = await _categoryBrandService.getCategories();
      final brands = await _categoryBrandService.getBrands();

      return {'products': products, 'categories': categories, 'brands': brands};
    } catch (e) {
      rethrow;
    }
  }

  /// Vuelve a cargar los datos
  void _reloadData() {
    setState(() {
      _initialDataFuture = _loadInitialData();
    });
  }

  // CORRECCIÓN: Firma de la función actualizada
  void _onApplyFilters(ProductFilters filters) {
    setState(() {
      _currentFilters = filters;
    });
    _reloadData();
    Navigator.of(context).pop(); // Cierra el drawer
  }

  // CORRECCIÓN: Función de limpieza añadida
  void _clearFilters() {
    setState(() {
      _currentFilters = ProductFilters();
    });
    _reloadData();
    Navigator.of(context).pop(); // Cierra el drawer
  }

  /// Maneja el cambio en la barra de búsqueda (con debounce)
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // (Aquí se podría añadir un debounce timer)
    _reloadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Asigna la key al Scaffold
      appBar: _buildAppBar(),
      // Usamos FutureBuilder para asegurar que los datos del drawer estén listos
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar productos:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final List<Product> products = snapshot.data!['products'];
          final List<Category> categories = snapshot.data!['categories'];
          final List<Brand> brands = snapshot.data!['brands'];

          // Ahora que tenemos los datos, construimos el Scaffold real
          return Scaffold(
            // CORRECCIÓN: Se usa 'endDrawer' para el filtro (lado derecho)
            endDrawer: ProductFilterDrawer(
              // CORRECCIÓN: Parámetros requeridos añadidos
              allCategories: categories,
              allBrands: brands,
              currentFilters: _currentFilters,
              onApplyFilters: _onApplyFilters,
              clearFilters: _clearFilters,
            ),
            body: Column(
              children: [
                _buildSearchField(),
                Expanded(
                  child: products.isEmpty
                      ? const Center(
                          child: Text('No se encontraron productos.'),
                        )
                      : _buildProductGrid(products),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// AppBar
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Catálogo de Productos'),
      actions: [
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color:
                _hasActiveFilters // Resalta el ícono si hay filtros
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () {
            // CORRECCIÓN: Abre el 'endDrawer' (lado derecho)
            _scaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ],
    );
  }

  /// Campo de búsqueda
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  /// Cuadrícula de productos
  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product);
      },
    );
  }
}
