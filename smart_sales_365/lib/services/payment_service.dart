// lib/services/payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sales_365/models/cart_item_model.dart';

class PaymentService {
  // Apunta a la URL de 'orders' de tu backend
  final String baseUrl = 'http://10.0.2.2:8000/api/orders';

  Future<Map<String, dynamic>> createCheckoutSession(
      Map<int, CartItem> items) async {
    // 1. Obtener el token de autenticación
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('No estás autenticado. Inicia sesión para pagar.');
    }

    // 2. Formatear los items del carrito como espera el backend
    // Tu backend espera: [{'product_id': X, 'quantity': Y}, ...]
    final lineItems = items.values.map((item) {
      return {
        'product_id': item.productDetails.id,
        'quantity': item.quantity,
      };
    }).toList();

    // 3. Llamar a la API del backend
    final response = await http.post(
      Uri.parse('$baseUrl/create-checkout-session/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token', // Enviar el token
      },
      body: json.encode({
        'line_items': lineItems,
      }),
    );

    // 4. Manejar la respuesta
    if (response.statusCode == 200) {
      return json.decode(response.body); // Devuelve {'session_id': '...'}
    } else {
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['error'] ?? 'Error al crear la sesión de pago');
    }
  }
}
