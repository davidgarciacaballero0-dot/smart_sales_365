// lib/providers/product_provider.dart
import 'package:flutter/material.dart';
import 'package:smart_sales_365/models/product_model.dart';
import 'package:smart_sales_365/services/product_service.dart';
import 'package:smart_sales_365/models/category_model.dart';
import 'package:smart_sales_365/models/brand_model.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  bool _isLoading = false;

  // --- NUEVOS CAMPOS PARA FILTROS AÑADIDOS ---
  Map<String, String> _filters = {};

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;
  bool get isLoading => _isLoading;
  Map<String, String> get filters => _filters;

  ProductProvider() {
    fetchAllData();
  }

  /// Carga productos, categorías y marcas al iniciar.
  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Hacemos las 3 llamadas en paralelo
      final results = await Future.wait([
        _productService.getProducts(
          params: _filters,
        ), // Carga productos con filtros (si hay)
        _productService.getCategories(),
        _productService.getBrands(),
      ]);

      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _brands = results[2] as List<Brand>;
    } catch (e) {
      // Manejar el error (ej. mostrar un mensaje)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vuelve a cargar solo los productos (usado al aplicar filtros).
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _productService.getProducts(params: _filters);
    } catch (e) {
      // Manejar error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NUEVOS MÉTODOS PARA FILTROS AÑADIDOS ---

  /// Aplica un filtro o lo quita si el valor está vacío,
  /// y automáticamente recarga los productos.
  void setFilter(String key, String value) {
    if (value.isEmpty) {
      _filters.remove(key);
    } else {
      _filters[key] = value;
    }
    notifyListeners();
    fetchProducts();
  }

  /// Limpia todos los filtros y recarga los productos.
  void clearFilters() {
    _filters = {};
    notifyListeners();
    fetchProducts();
  }

  // --- MÉTODO ANTIGUO MODIFICADO ---
  // Este método ya no es necesario aquí,
  // la pantalla de detalle puede usar el 'product_service' directamente.
  /*
  Future<Product> getProductById(int id) async {
    return await _productService.getProductById(id);
  }
  */
}
