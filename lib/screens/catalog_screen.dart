// lib/screens/catalog_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_import, use_build_context_synchronously, unnecessary_brace_in_string_interps

// CORRECCIÓN 1: Se eliminó la importación de 'package_wrapper.dart'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/models/products_response_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
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
  bool _isInitialized = false;

  // CORRECCIÓN: Se usa la clase ProductFilters en lugar de un Map
  ProductFilters _currentFilters = ProductFilters();
  String _searchQuery = '';

  // Paginación
  int _currentPage = 1;
  bool _hasMorePages = false;
  bool _isLoadingMore = false;
  List<Product> _allProducts = []; // Acumulador de productos

  // Timer para debounce de búsqueda
  Timer? _debounceTimer;

  // Variables para speech_to_text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = '';

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
    // Inicializar speech_to_text
    _speech = stt.SpeechToText();

    // Inicializar con datos vacíos temporalmente
    _initialDataFuture = Future.value({
      'products': <Product>[],
      'categories': <Category>[],
      'brands': <Brand>[],
    });

    // Cargar datos reales después de que el contexto esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initialDataFuture = _loadInitialData();
        });
      }
    });
  }

  /// Carga productos, categorías y marcas
  Future<Map<String, dynamic>> _loadInitialData() async {
    try {
      final String? token = context.read<AuthProvider>().token;

      // CORRECCIÓN: Convertimos los filtros a un Map para la API
      // Solo acepta: category, brand, min_price, max_price
      final Map<String, dynamic> apiFilters = {};

      // Filtros con los nombres exactos que espera el backend Django
      // Referencia: products/views.py línea 116-135
      if (_currentFilters.categoryId != null) {
        apiFilters['category'] = _currentFilters.categoryId.toString();
      }
      if (_currentFilters.brandId != null) {
        apiFilters['brand'] = _currentFilters.brandId.toString();
      }
      if (_currentFilters.minPrice != null) {
        apiFilters['min_price'] = _currentFilters.minPrice.toString();
      }
      if (_currentFilters.maxPrice != null) {
        apiFilters['max_price'] = _currentFilters.maxPrice.toString();
      }

      // Log omitido intencionalmente para evitar pausas si hay un breakpoint en esta línea
      // (antes: debugPrint('🔍 Filtros enviados al backend: $apiFilters'))
      // CORRECCIÓN: Usamos ProductsResponse con paginación
      final productsResponse = await _productService.getProducts(
        token: token,
        filters: apiFilters,
        page: 1, // Primera página
      );

      // Resetear estado de paginación
      _currentPage = 1;
      _hasMorePages = productsResponse.hasNextPage;
      _allProducts = productsResponse.products;

      // Cargamos los datos para el drawer
      final categories = await _categoryBrandService.getCategories();
      final brands = await _categoryBrandService.getBrands();

      debugPrint('✅ Products loaded: ${productsResponse.products.length}');
      debugPrint('📄 Has more pages: ${productsResponse.hasNextPage}');
      debugPrint('📊 Total count: ${productsResponse.count}');
      debugPrint('✅ Categories loaded: ${categories.length}');
      debugPrint('✅ Brands loaded: ${brands.length}');

      return {
        'products': productsResponse.products,
        'categories': categories,
        'brands': brands,
      };
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
    // NO cerrar drawer aquí - lo hace el drawer mismo
  }

  // CORRECCIÓN: Función de limpieza añadida
  void _clearFilters() {
    setState(() {
      _currentFilters = ProductFilters();
    });
    _reloadData();
    // NO cerrar drawer aquí - lo hace el drawer mismo
  }

  /// Maneja el cambio en la barra de búsqueda (solo actualiza el estado)
  void _onSearchChanged(String query) {
    // Solo actualizar el texto, NO buscar automáticamente
    setState(() {
      _searchQuery = query;
    });
  }

  /// Ejecuta la búsqueda cuando se presiona Enter
  void _executeSearch() {
    _reloadData();
  }

  /// Iniciar/detener reconocimiento de voz
  Future<void> _toggleListening() async {
    if (_isListening) {
      // Detener escucha
      await _speech.stop();
      setState(() {
        _isListening = false;
      });

      // Si se capturó texto, buscar y añadir producto
      if (_voiceText.isNotEmpty) {
        await _searchAndAddProductByVoice(_voiceText);
      }
    } else {
      // Solicitar permiso
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de micrófono denegado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Inicializar speech si es necesario
      bool available = await _speech.initialize(
        onError: (error) {
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );

      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reconocimiento de voz no disponible'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Iniciar escucha
      setState(() {
        _isListening = true;
        _voiceText = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceText = result.recognizedWords;
          });
        },
        localeId: 'es_ES', // Español
      );
    }
  }

  /// Buscar producto por nombre de voz y añadir al carrito
  Future<void> _searchAndAddProductByVoice(String productName) async {
    try {
      final String? token = context.read<AuthProvider>().token;

      // Buscar productos que coincidan con el nombre
      final productsResponse = await _productService.getProducts(
        token: token,
        filters: {'search': productName},
        page: 1,
      );

      if (productsResponse.products.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró producto: "$productName"'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Tomar el primer producto encontrado
      final product = productsResponse.products.first;

      // Añadir al carrito
      final cartProvider = context.read<CartProvider>();
      final success = await cartProvider.addToCart(
        token: token!,
        productId: product.id,
        quantity: 1,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${product.name}" añadido al carrito'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al añadir producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _voiceText = '';
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initialDataFuture,
      builder: (context, snapshot) {
        // Mostrar loading mientras inicializa o está esperando
        if (!_isInitialized ||
            snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Mostrar error si falla
        if (snapshot.hasError) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: _buildAppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar productos:\n${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reloadData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Validar que hay datos
        if (!snapshot.hasData) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: _buildAppBar(),
            body: const Center(child: Text('No se encontraron datos.')),
          );
        }

        final List<Product> products = snapshot.data!['products'];
        final List<Category> categories = snapshot.data!['categories'];
        final List<Brand> brands = snapshot.data!['brands'];

        // 🔍 FILTRADO LOCAL: El backend NO soporta búsqueda por nombre
        // Filtramos los productos localmente si hay texto de búsqueda
        final List<Product> filteredProducts = _searchQuery.trim().isEmpty
            ? products
            : products
                  .where(
                    (product) => product.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        // Construir UI principal con UN SOLO Scaffold
        return Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(),
          endDrawer: ProductFilterDrawer(
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
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.trim().isEmpty
                                  ? 'No se encontraron productos.'
                                  : 'No hay productos que coincidan con "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildProductGrid(filteredProducts)),
                          if (_hasMorePages) _buildLoadMoreButton(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// AppBar
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Catálogo de Productos'),
      actions: [
        // Botón de reconocimiento de voz
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : null,
          ),
          tooltip: _isListening
              ? 'Escuchando... "${_voiceText}"'
              : 'Buscar por voz',
          onPressed: _toggleListening,
        ),
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
          hintText: 'Escribe para filtrar productos',
          helperText: '💡 La búsqueda es local (filtra productos cargados)',
          helperMaxLines: 2,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: (value) {
          // Buscar cuando presionas Enter (solo actualiza el estado ya que es local)
          _executeSearch();
        },
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

  /// Botón "Cargar más" para paginación
  Widget _buildLoadMoreButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: _isLoadingMore
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          : ElevatedButton.icon(
              onPressed: _loadMoreProducts,
              icon: const Icon(Icons.add),
              label: const Text('Cargar más productos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
    );
  }

  /// Carga la siguiente página de productos
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final String? token = context.read<AuthProvider>().token;

      // Construir filtros API (usar las mismas claves que en _loadInitialData)
      // NOTA: la búsqueda por texto es local, no se envía al backend
      final Map<String, dynamic> apiFilters = {};
      if (_currentFilters.categoryId != null) {
        apiFilters['category'] = _currentFilters.categoryId.toString();
      }
      if (_currentFilters.brandId != null) {
        apiFilters['brand'] = _currentFilters.brandId.toString();
      }
      if (_currentFilters.minPrice != null) {
        apiFilters['min_price'] = _currentFilters.minPrice.toString();
      }
      if (_currentFilters.maxPrice != null) {
        apiFilters['max_price'] = _currentFilters.maxPrice.toString();
      }
      apiFilters.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty),
      );

      // Cargar siguiente página
      final nextPage = _currentPage + 1;
      final productsResponse = await _productService.getProducts(
        token: token,
        filters: apiFilters,
        page: nextPage,
      );

      setState(() {
        _currentPage = nextPage;
        _hasMorePages = productsResponse.hasNextPage;
        _allProducts.addAll(productsResponse.products);
        _isLoadingMore = false;
      });

      // Actualizar el Future para que el FutureBuilder se refresque
      setState(() {
        _initialDataFuture = Future.value({
          'products': _allProducts,
          'categories': [], // Ya están cargadas
          'brands': [], // Ya están cargadas
        });
      });

      debugPrint(
        '✅ Loaded page $nextPage: ${productsResponse.products.length} products',
      );
      debugPrint('📄 Total products now: ${_allProducts.length}');
    } catch (e) {
      debugPrint('❌ Error loading more products: $e');
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar más productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
