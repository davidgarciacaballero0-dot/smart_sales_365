// lib/services/order_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/providers/cart_provider.dart';

class OrderService {
  static const String _baseUrl = 'https://smartsales-backend.onrender.com/api';

  /// Crea un nuevo pedido en el backend y devuelve la URL de pago de Stripe.
  /// Requiere el 'token' de autenticación y el 'cartProvider'.
  Future<String> createOrder(String token, CartProvider cart) async {
    final Uri url = Uri.parse('$_baseUrl/orders/create/');

    // 1. Convierte los ítems del carrito al formato JSON que tu backend espera
    // (Tu backend espera una lista de {'product_id': X, 'quantity': Y})
    List<Map<String, dynamic>> orderItems = cart.items.map((item) {
      return {'product_id': item.product.id, 'quantity': item.quantity};
    }).toList();

    // El cuerpo de la petición
    final body = jsonEncode({
      'items': orderItems,
      // (Opcional) Tu backend también acepta 'shipping_address',
      // 'billing_address', etc. Podemos añadirlos aquí más tarde.
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-R8',
          // 2. ¡MUY IMPORTANTE! Inyecta el token de autenticación
          'Authorization': 'Token $token',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        // ¡Éxito! (201 = Creado)
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        // 3. Extrae la 'checkout_url' de la respuesta del backend
        final String? checkoutUrl = data['checkout_url'];

        if (checkoutUrl != null) {
          return checkoutUrl;
        } else {
          throw Exception('El backend no devolvió una checkout_url.');
        }
      } else {
        // Error (ej. 401 No Autorizado, 400 Bad Request)
        throw Exception(
          'Error al crear el pedido: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
