// lib/services/order_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/providers/cart_provider.dart';
// 1. IMPORTA LOS NUEVOS MODELOS DE PEDIDO QUE CREAMOS
import 'package:smartsales365/models/order_model.dart';

class OrderService {
  static const String _baseUrl = 'https://smartsales-backend.onrender.com/api';

  /// Crea un nuevo pedido en el backend y devuelve la URL de pago de Stripe.
  /// (Este es el método que ya tenías y corregimos)
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
          'Authorization': 'Bearer $token', // Corregido a 'Bearer'
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
        throw Exception(
          'Error al crear el pedido: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- ¡NUEVO MÉTODO! ---

  /// Obtiene el historial de pedidos del usuario autenticado.
  Future<List<Order>> getOrders(String token) async {
    // 2. Este es el endpoint de tu backend para listar pedidos (GET)
    final Uri url = Uri.parse('$_baseUrl/orders/');

    try {
      final response = await http.get(
        url,
        headers: {
          // 3. Es una ruta protegida, así que enviamos el token
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // 4. El backend nos devuelve una LISTA de pedidos
        final List<dynamic> ordersJson = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        // 5. Usamos el 'Order.fromJson' que creamos en el Paso 1
        //    para convertir cada objeto JSON en un objeto Order
        List<Order> orders = ordersJson
            .map((json) => Order.fromJson(json))
            .toList();

        return orders;
      } else {
        throw Exception(
          'Error al obtener los pedidos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
