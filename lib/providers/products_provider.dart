// lib/providers/products_provider.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/services/category_brand_service.dart';
import 'package:smartsales365/services/product_service.dart';
import 'package:smartsales365/widgets/product_filter_drawer.dart';

class ProductsProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryBrandService _categoryBrandService = CategoryBrandService();

  // Estado
  bool _isLoading = false;
  String? _error;

  // Datos
  final List<Product> _products = [];
  int _currentPage = 1;
  bool _hasMore = false;

  // Catálogos
  List<Category> _categories = [];
  List<Brand> _brands = [];

  // Filtros y búsqueda local
  ProductFilters _filters = ProductFilters();
  String _searchQuery = '';

  // Token opcional (para endpoints que lo aceptan)
  String? _token;

  // Getters expuestos
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;
  List<Product> get products {
    if (_searchQuery.trim().isEmpty) return List.unmodifiable(_products);
    final q = _searchQuery.toLowerCase();
    return _products
        .where((p) => p.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  bool get hasMore => _hasMore;
  ProductFilters get filters => _filters;
  String get searchQuery => _searchQuery;
  List<Category> get categories => List.unmodifiable(_categories);
  List<Brand> get brands => List.unmodifiable(_brands);

  void setAuthToken(String? token) {
    _token = token; // Puede ser null (endpoints públicos)
  }

  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    _products.clear();
    _currentPage = 1;
    notifyListeners();

    try {
      // Construir filtros para API
      final apiFilters = <String, dynamic>{};
      if (_filters.categoryId != null) {
        apiFilters['category'] = _filters.categoryId.toString();
      }
      if (_filters.brandId != null) {
        apiFilters['brand'] = _filters.brandId.toString();
      }
      if (_filters.minPrice != null) {
        apiFilters['min_price'] = _filters.minPrice.toString();
      }
      if (_filters.maxPrice != null) {
        apiFilters['max_price'] = _filters.maxPrice.toString();
      }

      final resp = await _productService.getProducts(
        token: _token,
        filters: apiFilters,
        page: 1,
      );

      _products.addAll(resp.products);
      _hasMore = resp.hasNextPage;
      _currentPage = 1;

      // Cargar catálogos si aún no los tenemos
      if (_categories.isEmpty) {
        _categories = await _categoryBrandService.getCategories();
      }
      if (_brands.isEmpty) {
        _brands = await _categoryBrandService.getBrands();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiFilters = <String, dynamic>{};
      if (_filters.categoryId != null) {
        apiFilters['category'] = _filters.categoryId.toString();
      }
      if (_filters.brandId != null) {
        apiFilters['brand'] = _filters.brandId.toString();
      }
      if (_filters.minPrice != null) {
        apiFilters['min_price'] = _filters.minPrice.toString();
      }
      if (_filters.maxPrice != null) {
        apiFilters['max_price'] = _filters.maxPrice.toString();
      }

      final nextPage = _currentPage + 1;
      final resp = await _productService.getProducts(
        token: _token,
        filters: apiFilters,
        page: nextPage,
      );

      _products.addAll(resp.products);
      _hasMore = resp.hasNextPage;
      _currentPage = nextPage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void applyFilters(ProductFilters filters) {
    _filters = filters;
    loadInitial();
  }

  void clearFilters() {
    _filters = ProductFilters();
    loadInitial();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners(); // Búsqueda es local
  }
}
