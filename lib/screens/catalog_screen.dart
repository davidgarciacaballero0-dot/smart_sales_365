// lib/screens/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/product_model.dart';
// 1. Importa el NUEVO servicio de productos
import 'package:smartsales365/services/product_service.dart';
// 2. Importa tu widget de tarjeta de producto
import 'package:smartsales365/widgets/product_card.dart';

// Convertimos esto a un StatefulWidget para manejar el estado de
// la carga, los errores y la lista de productos
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Instancia de nuestro nuevo servicio
  final ProductService _productService = ProductService();

  // Variables para manejar el estado de la pantalla
  bool _isLoading = true; // Controla el círculo de carga
  String? _errorMessage; // Guarda el mensaje de error si algo falla
  List<Product> _products = []; // La lista de productos a mostrar

  // Controlador para el campo de texto de búsqueda
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cuando la pantalla se carga por primera vez,
    // llamamos a la API para obtener TODOS los productos.
    _fetchProducts();
  }

  /// Método principal para obtener productos de la API.
  /// Acepta una 'query' (consulta) de búsqueda opcional.
  Future<void> _fetchProducts({String? query}) async {
    // Limpiamos cualquier error anterior
    _errorMessage = null;

    // Mostramos el indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamamos al servicio (con o sin 'query')
      final List<Product> fetchedProducts = await _productService.getProducts(
        query: query,
      );

      // Si todo sale bien, actualizamos la lista de productos
      setState(() {
        _products = fetchedProducts;
        _isLoading = false; // Ocultamos el indicador de carga
      });
    } catch (e) {
      // Si hay un error, lo guardamos para mostrarlo
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false; // Ocultamos el indicador de carga
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos una AppBar para poner la barra de búsqueda
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
        // 'bottom' nos permite poner la barra de búsqueda justo debajo del título
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0), // Altura de la barra
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos... (ej: "televisor")',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    30.0,
                  ), // Bordes redondeados
                  borderSide: BorderSide.none, // Sin borde
                ),
                filled: true,
                fillColor: Colors.grey[200], // Color de fondo
                contentPadding: EdgeInsets.zero, // Ajusta el padding interno
              ),
              // Esto se activa cuando el usuario presiona "Enter"
              // o el botón de buscar en el teclado.
              onSubmitted: (String query) {
                _fetchProducts(query: query);
              },
            ),
          ),
        ),
      ),
      // El cuerpo de la pantalla dependerá del estado (carga, error, éxito)
      body: _buildBody(),
    );
  }

  /// Widget auxiliar que decide qué mostrar en el cuerpo
  Widget _buildBody() {
    // ESTADO 1: CARGANDO
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ESTADO 2: ERROR
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

    // ESTADO 3: LISTA VACÍA (después de una búsqueda sin resultados)
    if (_products.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty
              ? 'No se encontraron productos para "${_searchController.text}"'
              : 'No hay productos disponibles.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ESTADO 4: ÉXITO (Mostrar la cuadrícula de productos)
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75, // Proporción de las tarjetas
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];

        // ¡PRÓXIMO PASO!
        // Haremos que esto sea "clicable" para ir al detalle
        return ProductCard(product: product);
      },
    );
  }
}
