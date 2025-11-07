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

    List<Map<String, dynamic>> orderItems = cart.items.map((item) {
      return {'product_id': item.product.id, 'quantity': item.quantity};
    }).toList();

    final body = jsonEncode({'items': orderItems});

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',

          // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
          // Cambiamos 'Token' por 'Bearer' para que coincida
          // con la autenticación JWT de tu backend.
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final String? checkoutUrl = data['checkout_url'];

        if (checkoutUrl != null) {
          return checkoutUrl;
        } else {
          throw Exception('El backend no devolvió una checkout_url.');
        }
      } else {
        // El error 401 que veías entrará aquí
        throw Exception(
          'Error al crear el pedido: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
