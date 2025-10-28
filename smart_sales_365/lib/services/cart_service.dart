// lib/services/cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_sales_365/models/cart_model.dart';
import 'package:smart_sales_365/models/cart_item_model.dart'; // Aunque CartModel lo incluye, es bueno tenerlo
import 'package:smart_sales_365/services/auth_service.dart'; // Para obtener el token

class CartService {
  final String _baseUrl = 'https://smartsales-backend.onrender.com/api';
  final AuthService _authService =
      AuthService(); // Instancia para acceder al token

  // --- Helper para obtener Headers con Token ---
  Future<Map<String, String>> _getAuthHeaders() async {
    final String? token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Usuario no autenticado. No se encontró token.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      // Usamos 'Bearer' porque simple-jwt usa JWTAuthentication
      'Authorization': 'Bearer $token',
    };
  }

  // --- Obtener el Carrito Actual (GET /api/cart/) ---
  Future<Cart> getCart() async {
    final Uri cartUrl = Uri.parse('$_baseUrl/cart/');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(cartUrl, headers: headers);

      if (response.statusCode == 200) {
        // El backend devuelve un solo objeto Cart
        return Cart.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        // DRF devuelve 404 si el carrito no existe (ej. usuario nuevo sin carrito)
        // Podríamos devolver un carrito vacío o manejarlo en el Provider
        print('ℹ️ Carrito no encontrado (404), posible usuario nuevo.');
        // Considera devolver un Cart 'vacío' o lanzar un error específico
        throw Exception('Carrito no encontrado.');
      } else {
        print(
          '❌ Error al obtener carrito (${response.statusCode}): ${response.body}',
        );
        throw Exception('Error al cargar el carrito.');
      }
    } catch (e) {
      print('❌ Error en CartService.getCart: $e');
      // Re-lanzar la excepción para que el Provider la maneje
      rethrow;
    }
  }

  // --- Añadir Item al Carrito (POST /api/cart/) ---
  // Devuelve el CartItem creado/actualizado
  Future<CartItem> addItemToCart({
    required int productId,
    int quantity = 1,
  }) async {
    final Uri cartUrl = Uri.parse('$_baseUrl/cart/');
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({'product_id': productId, 'quantity': quantity});

      final response = await http.post(cartUrl, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 200 OK si actualiza cantidad, 201 Created si es nuevo
        print('✅ Item añadido/actualizado en carrito: Producto ID $productId');
        return CartItem.fromJson(jsonDecode(response.body));
      } else {
        print(
          '❌ Error al añadir item (${response.statusCode}): ${response.body}',
        );
        throw Exception('Error al añadir producto al carrito.');
      }
    } catch (e) {
      print('❌ Error en CartService.addItemToCart: $e');
      rethrow;
    }
  }

  // --- Actualizar Cantidad de Item (PUT /api/cart/{item_id}/) ---
  // Devuelve el CartItem actualizado
  Future<CartItem> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    // Asegurarse que la cantidad sea al menos 1
    if (quantity < 1) {
      throw Exception(
        "La cantidad mínima es 1. Para eliminar, usa el método correspondiente.",
      );
    }
    final Uri itemUrl = Uri.parse('$_baseUrl/cart/$itemId/');
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({'quantity': quantity});

      final response = await http.put(itemUrl, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('✅ Cantidad actualizada para item ID $itemId a $quantity');
        return CartItem.fromJson(jsonDecode(response.body));
      } else {
        print(
          '❌ Error al actualizar item $itemId (${response.statusCode}): ${response.body}',
        );
        throw Exception('Error al actualizar la cantidad del producto.');
      }
    } catch (e) {
      print('❌ Error en CartService.updateCartItem: $e');
      rethrow;
    }
  }

  // --- Eliminar Item del Carrito (DELETE /api/cart/{item_id}/) ---
  // Devuelve true si fue exitoso
  Future<bool> removeCartItem({required int itemId}) async {
    final Uri itemUrl = Uri.parse('$_baseUrl/cart/$itemId/');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(itemUrl, headers: headers);

      if (response.statusCode == 204) {
        // 204 No Content = Éxito en DELETE
        print('🗑️ Item eliminado del carrito: ID $itemId');
        return true;
      } else {
        print(
          '❌ Error al eliminar item $itemId (${response.statusCode}): ${response.body}',
        );
        throw Exception('Error al eliminar el producto del carrito.');
      }
    } catch (e) {
      print('❌ Error en CartService.removeCartItem: $e');
      rethrow;
    }
  }

  // --- (Opcional) Vaciar Carrito Completo (DELETE /api/cart/) ---
  // Si tu backend tiene un endpoint para esto, añádelo aquí.
  // Podría ser una acción personalizada en el ViewSet.
  // Ejemplo: Future<bool> clearCart() async { ... }
}
