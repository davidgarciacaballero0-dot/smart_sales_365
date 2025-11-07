// lib/services/category_brand_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/category_model.dart';
import 'package:smartsales365/models/brand_model.dart';

class CategoryBrandService {
  static const String _baseUrl =
      'https://smartsales-backend.onrender.com/api/products';

  /// Obtiene la lista de todas las Categorías
  Future<List<Category>> getCategories() async {
    final Uri url = Uri.parse('$_baseUrl/categories/');
    print('Llamando a la API: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar categorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene la lista de todas las Marcas
  Future<List<Brand>> getBrands() async {
    final Uri url = Uri.parse('$_baseUrl/brands/');
    print('Llamando a la API: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList.map((json) => Brand.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar marcas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
