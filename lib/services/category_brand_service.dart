// lib/services/category_brand_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/category_model.dart';
import 'package:smartsales365/models/brand_model.dart';

class CategoryBrandService {
  static const String _baseUrl =
      'https://smartsales-backend.onrender.com/api/products';
  static const String _categoriesUrl = '$_baseUrl/categories/';
  static const String _brandsUrl = '$_baseUrl/brands/';

  Map<String, String> _getAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // --- MÉTODOS DE CATEGORÍA ---

  /// Obtiene la lista de todas las Categorías
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse(_categoriesUrl));
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

  /// Crea una nueva Categoría
  Future<Category> createCategory(
    String token,
    Map<String, dynamic> data,
  ) async {
    final body = jsonEncode({
      'name': data['name'],
      'description': data['description'],
    });
    try {
      final response = await http.post(
        Uri.parse(_categoriesUrl),
        headers: _getAuthHeaders(token),
        body: body,
      );
      if (response.statusCode == 201) {
        return Category.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Error al crear categoría: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualiza una Categoría existente
  Future<Category> updateCategory(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$_categoriesUrl$id/');
    final body = jsonEncode({
      'name': data['name'],
      'description': data['description'],
    });
    try {
      final response = await http.put(
        url,
        headers: _getAuthHeaders(token),
        body: body,
      );
      if (response.statusCode == 200) {
        return Category.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Error al actualizar categoría: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Elimina una Categoría
  Future<void> deleteCategory(String token, int id) async {
    final url = Uri.parse('$_categoriesUrl$id/');
    try {
      final response = await http.delete(url, headers: _getAuthHeaders(token));
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar categoría: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- MÉTODOS DE MARCA ---

  /// Obtiene la lista de todas las Marcas
  Future<List<Brand>> getBrands() async {
    try {
      final response = await http.get(Uri.parse(_brandsUrl));
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

  /// Crea una nueva Marca
  Future<Brand> createBrand(String token, Map<String, dynamic> data) async {
    final body = jsonEncode({
      'name': data['name'],
      'description': data['description'],
    });
    try {
      final response = await http.post(
        Uri.parse(_brandsUrl),
        headers: _getAuthHeaders(token),
        body: body,
      );
      if (response.statusCode == 201) {
        return Brand.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Error al crear marca: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualiza una Marca existente
  Future<Brand> updateBrand(
    String token,
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$_brandsUrl$id/');
    final body = jsonEncode({
      'name': data['name'],
      'description': data['description'],
    });
    try {
      final response = await http.put(
        url,
        headers: _getAuthHeaders(token),
        body: body,
      );
      if (response.statusCode == 200) {
        return Brand.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Error al actualizar marca: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Elimina una Marca
  Future<void> deleteBrand(String token, int id) async {
    final url = Uri.parse('$_brandsUrl$id/');
    try {
      final response = await http.delete(url, headers: _getAuthHeaders(token));
      if (response.statusCode != 204) {
        throw Exception('Error al eliminar marca: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
