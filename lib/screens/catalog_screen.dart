// lib/screens/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';
import 'package:smartsales365/models/product_model.dart';
// 'product_detail_screen.dart' no es necesario aquí, ProductCard lo maneja.
import 'package:smartsales365/services/category_brand_service.dart';
import 'package:smartsales365/services/product_service.dart';
import 'package:smartsales365/widgets/product_card.dart';
import 'package:smartsales365/widgets/product_filter_drawer.dart';
import 'package:smartsales365/providers/auth_provider.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ProductService _productService = ProductService();
  final CategoryBrandService _categoryBrandService = CategoryBrandService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = []; // La lista maestra original
  List<Product> _filteredProducts = []; // La lista que se muestra en la UI
  List<Brand> _brands = [];
  List<Category> _categories = [];

  bool _isLoading = true;
  String? _error;

  ProductFilters _currentFilters = ProductFilters();

  // Getter local para saber si hay filtros activos
  bool get _hasActiveFilters {
    return _currentFilters.brandId != null ||
        _currentFilters.categoryId != null ||
        _currentFilters.minPrice != null ||
        _currentFilters.maxPrice != null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = "Token no válido";
      });
      return;
    }

    try {
      final results = await Future.wait([
        // CORRECCIÓN (Error 1): getProducts usa un parámetro NOMBRADO 'token'
        _productService.getProducts(token: token),
        _categoryBrandService.getBrands(),
        _categoryBrandService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _products = results[0] as List<Product>;
          _brands = results[1] as List<Brand>;
          _categories = results[2] as List<Category>;

          _runFilterAndSearch();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error al cargar datos: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Función unificada para aplicar filtros Y búsqueda
  void _runFilterAndSearch() {
    List<Product> tempProducts = List.from(_products);

    // --- 1. Aplicar Filtros (del Drawer) ---
    if (_hasActiveFilters) {
      tempProducts = tempProducts.where((product) {
        // CORRECCIÓN (Error 2, 3, 4, 5): Acceder a 'brand' y 'category' como MAPAS
        final byBrand = _currentFilters.brandId == null
            ? true
            : product.brand!.id == _currentFilters.brandId;

        final byCategory = _currentFilters.categoryId == null
            ? true
            // Access category via dynamic with null-check in case Product has no 'category' getter
            : (product as dynamic).category != null
            ? (product as dynamic).category['id'] == _currentFilters.categoryId
            : false;

        final byMinPrice = _currentFilters.minPrice == null
            ? true
            : product.price >= _currentFilters.minPrice!;

        final byMaxPrice = _currentFilters.maxPrice == null
            ? true
            : product.price <= _currentFilters.maxPrice!;

        return byBrand && byCategory && byMinPrice && byMaxPrice;
      }).toList();
    }

    // --- 2. Aplicar Búsqueda (del TextField) ---
    final String query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempProducts = tempProducts.where((product) {
        final inName = product.name.toLowerCase().contains(query);
        final inBrand =
            (((product as dynamic).brand != null
                        ? (product as dynamic).brand['name']
                        : null) ??
                    '')
                .toLowerCase()
                .contains(query);

        // CORRECCIÓN (Error 3, 5): Access category via dynamic with null-check
        final inCategory =
            (((product as dynamic).category != null
                        ? (product as dynamic).category['name']
                        : null) ??
                    '')
                .toLowerCase()
                .contains(query);

        return inName || inBrand || inCategory;
      }).toList();
    }

    // --- 3. Actualizar la UI ---
    setState(() {
      _filteredProducts = tempProducts;
    });
  }

  /// Callback para el Drawer: se aplican nuevos filtros
  void _applyFilters(ProductFilters filters) {
    Navigator.of(context).pop(); // Cierra el drawer
    setState(() {
      _currentFilters = filters;
    });
    _runFilterAndSearch(); // Re-filtrar y buscar
  }

  /// Callback para el Drawer: se limpian los filtros
  void _clearFilters() {
    Navigator.of(context).pop(); // Cierra el drawer
    setState(() {
      _currentFilters = ProductFilters();
    });
    _runFilterAndSearch(); // Re-filtrar y buscar
  }

  void _openFilterDrawer() {
    Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _hasActiveFilters
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: _openFilterDrawer,
              );
            },
          ),
        ],
      ),

      // CORRECCIÓN (Errores 6, 7, 8):
      // Usar los nombres de parámetros correctos del constructor de ProductFilterDrawer
      endDrawer: ProductFilterDrawer(
        allCategories: _categories,
        allBrands: _brands,
        currentFilters: _currentFilters,
        onApplyFilters: _applyFilters,
        clearFilters: _clearFilters,
      ),

      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) => _runFilterAndSearch(),
            ),
          ),
          // Cuerpo principal (Lista de productos)
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('No hay productos disponibles en este momento.'),
      );
    }

    if (_filteredProducts.isEmpty) {
      return const Center(
        child: Text('No se encontraron productos con esos criterios.'),
      );
    }

    // Grid de productos
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];

        return ProductCard(
          product: product,
          // onTap se maneja dentro de ProductCard
        );
      },
    );
  }
}
