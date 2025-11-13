// lib/services/cart_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/cart_model.dart';
import 'package:smartsales365/services/api_service.dart';

/// [CORREGIDO] Este servicio ha sido modificado para funcionar con un backend
/// que no devuelve el carrito completo en las operaciones PUT/POST/DELETE.
///
/// Cada operación exitosa (añadir, actualizar, eliminar) ahora realiza
/// una SEGUNDA llamada a getCart(token) para re-sincronizar el estado.
///
class CartService extends ApiService {
  final String _cartPath = 'cart';

  /// Helper privado para retry automático en errores 502/503
  /// (Esta función no se modifica)
  Future<T> _retryOnServerError<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 1);

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final isServerError =
            e.toString().contains('502') ||
            e.toString().contains('503') ||
            e.toString().contains('504');

        if (!isServerError || attempt >= maxRetries) {
          rethrow; // No reintentar si no es error de servidor o se acabaron los intentos
        }

        print(
          '⚠️ Error de servidor (intento $attempt/$maxRetries), reintentando en ${delay.inSeconds}s...',
        );
        await Future.delayed(delay);
        delay *= 2; // Backoff exponencial
      }
    }
  }

  /// Obtiene el carrito del usuario actual
  /// (Esta función no se modifica)
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
  /// [CORREGIDO] Ahora llama a getCart(token) si tiene éxito (200 o 201)
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
        // [CORREGIDO] El backend respondió que añadió el item (aunque devolvió un CartItem).
        // Para sincronizar, llamamos a getCart() para obtener el carrito completo.
        print('✅ Item añadido, actualizando carrito completo...');
        return await getCart(token);
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
  /// [CORREGIDO] Ahora llama a getCart(token) si tiene éxito (200)
  Future<Cart> updateCartItem({
    required String token,
    required int itemId,
    required int quantity,
  }) async {
    if (quantity < 0) {
      throw Exception('La cantidad no puede ser negativa');
    }

    return await _retryOnServerError(() async {
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
          // [CORREGIDO] El backend respondió que actualizó el item (aunque devolvió un CartItem).
          // Para sincronizar, llamamos a getCart() para obtener el carrito completo.
          print('✅ Item actualizado, actualizando carrito completo...');
          return await getCart(token);
        } else if (response.statusCode == 400) {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          throw Exception(errorData['error'] ?? 'Error al actualizar el item');
        } else if (response.statusCode == 404) {
          throw Exception('Item no encontrado en el carrito');
        } else {
          throw Exception(
            'Error al actualizar el item: ${response.statusCode}',
          );
        }
      } catch (e) {
        throw Exception('Error al actualizar el item: $e');
      }
    });
  }

  /// Elimina un item del carrito
  ///
  /// [CORREGIDO] Acepta 204 (No Content) como éxito y llama a getCart(token)
  Future<Cart> removeFromCart({
    required String token,
    required int itemId,
  }) async {
    return await _retryOnServerError(() async {
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

        // [CORREGIDO] Aceptamos 200 Y 204 como éxito.
        if (response.statusCode == 200 || response.statusCode == 204) {
          // [CORREGIDO] El backend respondió que eliminó el item (con 204).
          // Para sincronizar, llamamos a getCart() para obtener el carrito completo.
          print('✅ Item eliminado, actualizando carrito completo...');
          return await getCart(token);
        } else if (response.statusCode == 404) {
          throw Exception('Item no encontrado en el carrito');
        } else {
          // [CORREGIDO] El error 204 ya no caerá aquí.
          throw Exception(
            'Error al eliminar del carrito: ${response.statusCode}',
          );
        }
      } catch (e) {
        if (e is Exception) rethrow; // Volver a lanzar excepciones conocidas
        throw Exception('Error al eliminar del carrito: $e');
      }
    });
  }

  /// Vacía completamente el carrito eliminando todos los items
  /// (Esta función no se modifica, pero ahora usará el nuevo removeFromCart)
  Future<Cart> clearCart(String token) async {
    return await _retryOnServerError(() async {
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
    });
  }

  /// Helper: Incrementa la cantidad de un item en 1
  /// (Esta función no se modifica, usará el nuevo updateCartItem)
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
  /// (Esta función no se modifica, usará el nuevo updateCartItem/removeFromCart)
  Future<Cart> decrementItem({
    required String token,
    required int itemId,
    required int currentQuantity,
  }) async {
    if (currentQuantity <= 1) {
      // Es más seguro llamar a removeFromCart directamente
      return await removeFromCart(token: token, itemId: itemId);
    }
    return await updateCartItem(
      token: token,
      itemId: itemId,
      quantity: currentQuantity - 1,
    );
  }
}
