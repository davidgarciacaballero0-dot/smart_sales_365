// lib/providers/product_provider.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/services/product_service.dart';

// Definimos los posibles estados de carga de los productos
enum ProductStatus {
  idle, // Estado inicial, aún no se han cargado
  loading, // Cargando productos desde la API
  loaded, // Productos cargados exitosamente
  error, // Ocurrió un error al cargar
}

class ProductProvider with ChangeNotifier {
  // Instancia del servicio
  final ProductService _productService = ProductService();

  // --- Variables de Estado Privadas ---
  List<Product> _products = [];
  ProductStatus _status = ProductStatus.idle;
  String _errorMessage = '';

  // --- Getters Públicos ---
  List<Product> get products => _products;
  ProductStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == ProductStatus.loading;
  bool get hasError => _status == ProductStatus.error;

  // --- Constructor ---
  // Podemos llamar a loadProducts() aquí si queremos cargar
  // los productos tan pronto como se crea el provider.
  // O podemos llamarlo manualmente desde la UI (ej. HomeScreen).
  // Por ahora, lo dejaremos para llamarlo manualmente.
  // ProductProvider() {
  //   loadProducts();
  // }

  // --- Función para cargar los productos ---
  Future<void> loadProducts() async {
    // Evitar recargas innecesarias si ya está cargando
    if (_status == ProductStatus.loading) return;

    _status = ProductStatus.loading;
    _errorMessage = '';
    notifyListeners(); // Notifica a la UI que empezamos a cargar

    try {
      _products = await _productService.fetchProducts();
      _status = ProductStatus.loaded;
      print('🛒 Productos cargados en Provider: ${_products.length}');
    } catch (e) {
      _products = []; // Limpiar lista en caso de error
      _status = ProductStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('❌ Error cargando productos en Provider: $_errorMessage');
    } finally {
      notifyListeners(); // Notifica a la UI el resultado (éxito o error)
    }
  }

  // --- (Opcional) Función para buscar un producto por ID en la lista ya cargada ---
  Product? findProductById(int id) {
    try {
      // Busca en la lista local, no hace llamada a la API
      return _products.firstWhere((prod) => prod.id == id);
    } catch (e) {
      // Si no lo encuentra
      return null;
    }
  }
}
