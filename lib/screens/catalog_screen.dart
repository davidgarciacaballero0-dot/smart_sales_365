// lib/screens/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/services/product_service.dart';
import 'package:smartsales365/widgets/product_card.dart';
// 1. IMPORTA EL NUEVO DRAWER DE FILTROS
import 'package:smartsales365/widgets/product_filter_drawer.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ProductService _productService = ProductService();

  // Estado de carga
  bool _isLoading = true;
  String? _errorMessage;
  List<Product> _products = [];

  // Controlador de búsqueda
  final TextEditingController _searchController = TextEditingController();

  // 2. ESTADO PARA LOS FILTROS
  //    Guardamos los filtros aplicados aquí
  ProductFilters _currentFilters = ProductFilters();

  // 3. GlobalKey para el Scaffold (necesario para abrir el Drawer)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Carga inicial
  }

  /// Método principal para cargar/recargar productos
  /// Ahora usa los filtros guardados
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 4. Llama al servicio con TODOS los filtros
      final List<Product> fetchedProducts = await _productService.getProducts(
        query: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        categoryId: _currentFilters.categoryId,
        brandId: _currentFilters.brandId,
        minPrice: _currentFilters.minPrice,
        maxPrice: _currentFilters.maxPrice,
      );

      setState(() {
        _products = fetchedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // 5. Callback que recibe los filtros del Drawer
  void _onApplyFilters(ProductFilters newFilters) {
    setState(() {
      _currentFilters = newFilters;
    });
    // Vuelve a cargar los productos con los nuevos filtros
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    // 6. Determina si hay filtros activos (para el ícono)
    final bool hasActiveFilters =
        _currentFilters.categoryId != null ||
        _currentFilters.brandId != null ||
        (_currentFilters.minPrice != null && _currentFilters.minPrice! > 0) ||
        (_currentFilters.maxPrice != null && _currentFilters.maxPrice! > 0);

    return Scaffold(
      key: _scaffoldKey, // 7. Asigna el GlobalKey
      // 8. Añade un 'endDrawer' (el panel que se desliza desde la derecha)
      endDrawer: ProductFilterDrawer(
        currentFilters: _currentFilters,
        onApplyFilters: _onApplyFilters,
      ),

      appBar: AppBar(
        title: Text(
          'Tienda',
          style: TextStyle(
            color: Colors.blueGrey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // 9. Botón para ABRIR el drawer de filtros
          IconButton(
            tooltip: 'Filtrar',
            icon: Icon(
              // 10. El ícono cambia si hay filtros activos
              hasActiveFilters ? Icons.filter_list_alt : Icons.filter_list,
              color: hasActiveFilters
                  ? Theme.of(context).primaryColor
                  : Colors.black54,
            ),
            onPressed: () {
              // 11. Usa el key para abrir el endDrawer
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
        // Barra de búsqueda (sin cambios)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos... (ej: "tv")',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (String query) {
                // Al buscar, aplica el filtro de texto y los filtros existentes
                _fetchProducts();
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  /// Método helper para construir el cuerpo (sin cambios)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error al cargar productos:\n$_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            (_searchController.text.isNotEmpty || hasActiveFilters)
                ? 'No se encontraron productos que coincidan con tus filtros.'
                : 'No hay productos disponibles.',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductCard(product: product);
      },
    );
  }
}
