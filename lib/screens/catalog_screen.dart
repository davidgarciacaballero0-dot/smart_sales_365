// lib/screens/catalog_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_import, use_build_context_synchronously, unnecessary_brace_in_string_interps

// CORRECCIÓN 1: Se eliminó la importación de 'package_wrapper.dart'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/providers/products_provider.dart';
import 'package:smartsales365/widgets/product_card.dart';
import 'package:smartsales365/widgets/product_filter_drawer.dart';
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Timer para debounce de búsqueda
  Timer? _debounceTimer;

  // Variables para speech_to_text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = '';

  // Getter para saber si hay filtros activos
  bool get _hasActiveFilters =>
      context.read<ProductsProvider>().filters.brandId != null ||
      context.read<ProductsProvider>().filters.categoryId != null ||
      context.read<ProductsProvider>().filters.minPrice != null ||
      context.read<ProductsProvider>().filters.maxPrice != null;

  @override
  void initState() {
    super.initState();
    // Inicializar speech_to_text
    _speech = stt.SpeechToText();
    // Vincular token y cargar datos en provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final products = context.read<ProductsProvider>();
      products.setAuthToken(auth.token);
      await products.loadInitial();
    });
  }

  @override
  bool get wantKeepAlive => true;

  /// Vuelve a cargar los datos
  Future<void> _reloadData() async {
    final auth = context.read<AuthProvider>();
    final products = context.read<ProductsProvider>();
    products.setAuthToken(auth.token);
    await products.loadInitial();
  }

  // CORRECCIÓN: Firma de la función actualizada
  void _onApplyFilters(ProductFilters filters) {
    context.read<ProductsProvider>().applyFilters(filters);
  }

  // CORRECCIÓN: Función de limpieza añadida
  void _clearFilters() {
    context.read<ProductsProvider>().clearFilters();
  }

  /// Maneja el cambio en la barra de búsqueda (solo actualiza el estado)
  void _onSearchChanged(String query) {
    // Solo actualizar el texto, NO buscar automáticamente
    setState(() {
      _searchQuery = query;
    });
    // Búsqueda local en provider (sin golpear backend)
    context.read<ProductsProvider>().setSearchQuery(query);
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
      final productsProvider = context.read<ProductsProvider>();
      // Buscar localmente en los productos cargados
      final matches = productsProvider.products
          .where(
            (p) => p.name.toLowerCase().contains(productName.toLowerCase()),
          )
          .toList();

      if (matches.isEmpty) {
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
      final product = matches.first;

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
    super.build(context);
    return Consumer<ProductsProvider>(
      builder: (context, productsProvider, _) {
        final products = productsProvider.products;
        final categories = productsProvider.categories;
        final brands = productsProvider.brands;

        return Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(),
          endDrawer: ProductFilterDrawer(
            allCategories: categories,
            allBrands: brands,
            currentFilters: productsProvider.filters,
            onApplyFilters: _onApplyFilters,
            clearFilters: _clearFilters,
          ),
          body: Column(
            children: [
              _buildSearchField(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reloadData,
                  child: productsProvider.isLoading && products.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : products.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Column(
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
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: _buildProductGrid(products)),
                            if (productsProvider.hasMore)
                              _buildLoadMoreButton(),
                          ],
                        ),
                ),
              ),
              if (productsProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    productsProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
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
      key: const PageStorageKey('catalog-grid'),
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
      child: Consumer<ProductsProvider>(
        builder: (context, provider, _) => ElevatedButton.icon(
          onPressed: provider.isLoading ? null : _loadMoreProducts,
          icon: const Icon(Icons.add),
          label: const Text('Cargar más productos'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  /// Carga la siguiente página de productos
  Future<void> _loadMoreProducts() async {
    await context.read<ProductsProvider>().loadMore();
  }
}
