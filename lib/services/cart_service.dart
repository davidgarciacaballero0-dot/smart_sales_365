// lib/services/cart_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/cart_model.dart';
import 'package:smartsales365/services/api_service.dart';

/// Servicio para manejar operaciones del carrito
/// Backend endpoint: GET/POST/PUT/DELETE /api/cart/
///
/// Estructura del backend (CartViewSet):
/// - GET: Obtiene o crea automáticamente el carrito del usuario
/// - POST: Añade un producto al carrito {product_id, quantity}
/// - PUT: Actualiza la cantidad de un item {item_id, quantity}
/// - DELETE: Elimina un item del carrito {item_id}
class CartService extends ApiService {
  final String _cartPath = 'cart';

  /// Obtiene el carrito del usuario actual
  /// El backend automáticamente crea el carrito si no existe (get_or_create)
  ///
  /// Requiere: token de autenticación
  /// Retorna: Cart con todos los items y total calculado
  Future<Cart> getCart(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/$_cartPath/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return Cart.fromJson(jsonData);
      } else {
        throw Exception('Error al obtener el carrito: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener el carrito: $e');
    }
  }

  /// Añade un producto al carrito
  ///
  /// Backend espera: {product_id: int, quantity: int}
  /// - Si el producto ya existe, actualiza la cantidad
  /// - Valida que quantity > 0
  /// - Valida que hay stock suficiente
  ///
  /// Requiere: token, productId, quantity
  /// Retorna: Cart actualizado
  Future<Cart> addToCart({
    required String token,
    required int productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/$_cartPath/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'product_id': productId, 'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return Cart.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        // Error de validación (ej: stock insuficiente)
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['error'] ?? 'Error al añadir al carrito');
      } else {
        throw Exception('Error al añadir al carrito: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al añadir al carrito: $e');
    }
  }

  /// Actualiza la cantidad de un item en el carrito
  ///
  /// Backend espera: {item_id: int, quantity: int}
  /// - Si quantity = 0, elimina el item
  /// - Valida stock disponible
  ///
  /// Requiere: token, itemId, quantity
  /// Retorna: Cart actualizado
  Future<Cart> updateCartItem({
    required String token,
    required int itemId,
    required int quantity,
  }) async {
    if (quantity < 0) {
      throw Exception('La cantidad no puede ser negativa');
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/$_cartPath/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'item_id': itemId, 'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return Cart.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['error'] ?? 'Error al actualizar el item');
      } else if (response.statusCode == 404) {
        throw Exception('Item no encontrado en el carrito');
      } else {
        throw Exception('Error al actualizar el item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar el item: $e');
    }
  }

  /// Elimina un item del carrito
  ///
  /// Backend espera: {item_id: int}
  ///
  /// Requiere: token, itemId
  /// Retorna: Cart actualizado (sin el item eliminado)
  Future<Cart> removeFromCart({
    required String token,
    required int itemId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/$_cartPath/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'item_id': itemId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return Cart.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception('Item no encontrado en el carrito');
      } else {
        throw Exception(
          'Error al eliminar del carrito: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al eliminar del carrito: $e');
    }
  }

  /// Vacía completamente el carrito eliminando todos los items
  ///
  /// Requiere: token
  /// Retorna: Cart vacío
  Future<Cart> clearCart(String token) async {
    try {
      // Primero obtener el carrito para conocer los items
      final cart = await getCart(token);

      // Eliminar cada item uno por uno
      for (var item in cart.items) {
        await removeFromCart(token: token, itemId: item.id);
      }

      // Retornar carrito actualizado
      return await getCart(token);
    } catch (e) {
      throw Exception('Error al vaciar el carrito: $e');
    }
  }

  /// Helper: Incrementa la cantidad de un item en 1
  Future<Cart> incrementItem({
    required String token,
    required int itemId,
    required int currentQuantity,
  }) async {
    return await updateCartItem(
      token: token,
      itemId: itemId,
      quantity: currentQuantity + 1,
    );
  }

  /// Helper: Decrementa la cantidad de un item en 1
  /// Si la cantidad llega a 0, elimina el item
  Future<Cart> decrementItem({
    required String token,
    required int itemId,
    required int currentQuantity,
  }) async {
    if (currentQuantity <= 1) {
      return await removeFromCart(token: token, itemId: itemId);
    }
    return await updateCartItem(
      token: token,
      itemId: itemId,
      quantity: currentQuantity - 1,
    );
  }
}
