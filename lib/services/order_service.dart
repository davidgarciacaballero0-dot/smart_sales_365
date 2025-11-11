// lib/services/order_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsales365/models/order_model.dart';
import 'package:smartsales365/services/api_service.dart';

/// Servicio para manejar operaciones de órdenes
/// Backend endpoints:
/// - POST /api/orders/create_order_from_cart/ (crea orden desde carrito)
/// - GET /api/orders/ (lista órdenes del usuario)
/// - GET /api/orders/{id}/ (detalle de orden específica)
/// - POST /api/stripe/create-checkout-session/ (crea sesión de pago Stripe)
///
/// IMPORTANTE: El endpoint correcto es create_order_from_cart (action del viewset)
/// NO usar /orders/create/ que no existe en el backend
class OrderService extends ApiService {
  final String _ordersPath = 'orders';
  final String _stripePath = 'stripe';

  /// Crea una orden a partir del carrito actual del usuario
  ///
  /// Backend endpoint: POST /api/orders/create_order_from_cart/
  /// Body esperado: {shipping_address: string, shipping_phone: string}
  ///
  /// El backend automáticamente:
  /// - Toma los items del carrito del usuario
  /// - Crea la orden con status PENDIENTE
  /// - Vacía el carrito
  /// - Retorna la orden creada
  ///
  /// Requiere: token, shippingAddress, shippingPhone
  /// Retorna: Order creada
  Future<Order> createOrderFromCart({
    required String token,
    required String shippingAddress,
    required String shippingPhone,
  }) async {
    if (shippingAddress.trim().isEmpty) {
      throw Exception('La dirección de envío es requerida');
    }
    if (shippingPhone.trim().isEmpty) {
      throw Exception('El teléfono de contacto es requerido');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/$_ordersPath/create_order_from_cart/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'shipping_address': shippingAddress,
              'shipping_phone': shippingPhone,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return Order.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['error'] ?? 'Error al crear la orden');
      } else {
        throw Exception('Error al crear la orden: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear la orden: $e');
    }
  }

  /// Obtiene el historial de órdenes del usuario autenticado
  ///
  /// Backend endpoint: GET /api/orders/
  /// El backend automáticamente filtra las órdenes del usuario actual
  ///
  /// Requiere: token
  /// Retorna: Lista de órdenes ordenadas por fecha (más reciente primero)
  Future<List<Order>> getOrders(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/$_ordersPath/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        List<Order> orders = ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();

        return orders;
      } else {
        throw Exception('Error al obtener órdenes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener órdenes: $e');
    }
  }

  /// Obtiene el detalle de una orden específica
  ///
  /// Backend endpoint: GET /api/orders/{id}/
  /// Retorna la orden completa con todos los items y detalles
  ///
  /// Requiere: token, orderId
  /// Retorna: Order con todos los detalles
  Future<Order> getOrderById({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/$_ordersPath/$orderId/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return Order.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception('Orden no encontrada');
      } else {
        throw Exception('Error al obtener la orden: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener la orden: $e');
    }
  }

  /// Crea una sesión de pago de Stripe para una orden
  ///
  /// Backend endpoint: POST /api/stripe/create-checkout-session/
  /// Body esperado: {order_id: int}
  ///
  /// El backend:
  /// - Crea la sesión de checkout en Stripe
  /// - Guarda el stripe_checkout_id en la orden
  /// - Retorna la URL de checkout para redirigir al usuario
  ///
  /// Requiere: token, orderId
  /// Retorna: URL de Stripe checkout
  Future<String> createStripeCheckoutSession({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/$_stripePath/create-checkout-session/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'order_id': orderId}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        final String? checkoutUrl = jsonData['checkout_url'];

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          return checkoutUrl;
        } else {
          throw Exception('El backend no devolvió una URL de pago válida');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['error'] ?? 'Error al crear sesión de pago');
      } else if (response.statusCode == 404) {
        throw Exception('Orden no encontrada');
      } else {
        throw Exception(
          'Error al crear sesión de pago: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al crear sesión de pago: $e');
    }
  }

  /// Flujo completo: Crear orden y obtener URL de pago en un solo paso
  ///
  /// 1. Crea la orden desde el carrito
  /// 2. Crea la sesión de Stripe
  /// 3. Retorna la URL de checkout
  ///
  /// Requiere: token, shippingAddress, shippingPhone
  /// Retorna: URL de Stripe checkout
  Future<String> createOrderAndCheckout({
    required String token,
    required String shippingAddress,
    required String shippingPhone,
  }) async {
    try {
      // Paso 1: Crear orden desde carrito
      final order = await createOrderFromCart(
        token: token,
        shippingAddress: shippingAddress,
        shippingPhone: shippingPhone,
      );

      // Paso 2: Crear sesión de Stripe
      final checkoutUrl = await createStripeCheckoutSession(
        token: token,
        orderId: order.id,
      );

      return checkoutUrl;
    } catch (e) {
      throw Exception('Error en el proceso de checkout: $e');
    }
  }

  /// Obtiene la URL del recibo en PDF
  ///
  /// Backend endpoint: GET /api/receipt/{order_id}/pdf/
  ///
  /// Requiere: token, orderId
  /// Retorna: URL del PDF
  String getReceiptPdfUrl(int orderId) {
    return '$baseUrl/receipt/$orderId/pdf/';
  }

  /// Obtiene la URL del recibo en HTML
  ///
  /// Backend endpoint: GET /api/receipt/{order_id}/
  ///
  /// Requiere: token, orderId
  /// Retorna: URL del HTML
  String getReceiptHtmlUrl(int orderId) {
    return '$baseUrl/receipt/$orderId/';
  }
}
