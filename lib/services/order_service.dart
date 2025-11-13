// lib/services/order_service.dart

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
      print('📦 Creando orden desde carrito...');
      print('🔍 URL: $baseUrl/$_ordersPath/create_order_from_cart/');
      print('📍 Dirección: $shippingAddress');
      print('📞 Teléfono: $shippingPhone');

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

      print('📡 Status Code orden: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ Orden creada exitosamente: Orden ID ${jsonData['id']}');
        return Order.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        // Intentar extraer mensaje de error específico del backend
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          print('❌ Error 400: $errorData');

          // Manejar diferentes formatos de error del backend
          String errorMessage = 'Error al crear la orden';
          if (errorData is Map) {
            if (errorData.containsKey('error')) {
              errorMessage = errorData['error'].toString();
            } else if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'].toString();
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'].toString();
            }
          }
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception) rethrow;
          print('❌ No se pudo parsear error 400: ${response.body}');
          throw Exception(
            'Error al crear la orden. Verifica que el carrito tenga productos.',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente');
      } else if (response.statusCode == 500) {
        print('❌ Error 500 del servidor: ${response.body}');
        throw Exception('Error del servidor al crear la orden');
      } else {
        print('❌ Error HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
          'Error al crear la orden (código ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      print('❌ Excepción en createOrderFromCart: $e');
      throw Exception('Error de conexión al crear la orden');
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
  ///
  /// Excepciones:
  /// - TimeoutException: Tiempo de espera agotado (>30s)
  /// - SocketException: Sin conexión a internet
  /// - FormatException: Respuesta JSON inválida del backend
  /// - Exception: Otros errores (orden no encontrada, backend error, etc.)
  Future<String> createStripeCheckoutSession({
    required String token,
    required int orderId,
  }) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💳 STRIPE CHECKOUT: Iniciando creación de sesión');
      print('📋 Orden ID: $orderId');
      print('🔗 Endpoint: $baseUrl/$_stripePath/create-checkout-session/');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final requestBody = jsonEncode({'order_id': orderId});
      print('📤 Request Body: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/$_stripePath/create-checkout-session/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏰ TIMEOUT: La solicitud tardó más de 30 segundos');
              throw TimeoutException(
                'La creación de la sesión de pago tardó demasiado. '
                'Por favor, verifica tu conexión a internet e intenta nuevamente.',
              );
            },
          );

      print('📡 Status Code: ${response.statusCode}');
      print('━━━━━━━━ RESPONSE RAW COMPLETA ━━━━━━━━');
      print('📦 Response Body COMPLETO:');
      print(response.body);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // CASO 1: Respuesta puede ser string directo (URL pura)
        final responseBody = response.body.trim();
        if (responseBody.startsWith('http://') ||
            responseBody.startsWith('https://')) {
          print('🎯 CASO ESPECIAL: Respuesta es URL directa (sin JSON)');
          final uri = Uri.tryParse(responseBody);
          if (uri != null && uri.hasScheme && uri.hasAuthority) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('✅ STRIPE CHECKOUT: URL directa detectada');
            print('🔗 URL: $responseBody');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return responseBody;
          }
        }

        // CASO 2: Respuesta JSON (esperado)
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ Response JSON parseado exitosamente');
        print('🔍 Tipo de respuesta: ${jsonData.runtimeType}');
        print('🔍 JSON completo: $jsonData');
        print(
          '🔍 Keys disponibles: ${jsonData is Map ? jsonData.keys.toList() : "No es Map"}',
        );

        // Intentar múltiples formatos de respuesta del backend
        String? checkoutUrl;

        if (jsonData is Map) {
          // Formatos directos (orden de prioridad)
          checkoutUrl = jsonData['url']
              ?.toString(); // ← Formato principal del backend
          checkoutUrl ??= jsonData['checkout_url']?.toString();
          checkoutUrl ??= jsonData['session_url']?.toString();
          checkoutUrl ??= jsonData['payment_url']?.toString();
          checkoutUrl ??= jsonData['stripe_url']?.toString();

          // CASO ESPECIAL: Backend devolvió 'id' de sesión Stripe sin URL
          if ((checkoutUrl == null || checkoutUrl.isEmpty) &&
              jsonData.containsKey('id')) {
            final sessionId = jsonData['id']?.toString();
            if (sessionId != null && sessionId.startsWith('cs_')) {
              print('🎯 CASO ESPECIAL: Construyendo URL desde session ID');
              // Stripe Checkout URL pattern
              checkoutUrl = 'https://checkout.stripe.com/c/pay/$sessionId';
              print('✅ URL construida: $checkoutUrl');
            }
          }

          // Formato potencial: nested 'data' u otro objeto con la URL
          if ((checkoutUrl == null || checkoutUrl.isEmpty) &&
              jsonData.isNotEmpty) {
            print('🔍 Buscando URL en estructura nested...');
            for (final entry in jsonData.entries) {
              final value = entry.value;
              if (value is String && value.startsWith('http')) {
                checkoutUrl = value;
                print('✅ URL encontrada en key: ${entry.key}');
                break;
              } else if (value is Map) {
                for (final v2Entry in value.entries) {
                  if (v2Entry.value is String &&
                      (v2Entry.value as String).startsWith('http')) {
                    checkoutUrl = v2Entry.value as String;
                    print(
                      '✅ URL encontrada en nested key: ${entry.key}.${v2Entry.key}',
                    );
                    break;
                  }
                }
              }
              if (checkoutUrl != null) break;
            }
          }

          // Último fallback: buscar primera cadena con https en valores
          if (checkoutUrl == null || checkoutUrl.isEmpty) {
            print('🔍 Último fallback: buscando cualquier URL https...');
            final flatValues = jsonData.values.whereType<String>();
            for (final v in flatValues) {
              if (v.contains('https://')) {
                checkoutUrl = v;
                print('✅ URL encontrada en fallback: $checkoutUrl');
                break;
              }
            }
          }
        }

        // Validar que la URL sea válida
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          // Validar formato de URL
          final uri = Uri.tryParse(checkoutUrl);
          if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
            print('❌ URL inválida: $checkoutUrl');
            throw FormatException(
              'La URL de pago retornada por el backend no es válida: $checkoutUrl',
            );
          }

          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('✅ STRIPE CHECKOUT: Sesión creada exitosamente');
          print('🔗 URL: $checkoutUrl');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return checkoutUrl;
        } else {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('❌ ERROR: No se encontró URL de pago en la respuesta');
          print('❌ Respuesta completa del backend:');
          print(jsonData);
          print('❌ Keys buscados: url, checkout_url, session_url, payment_url');

          // Mostrar todos los keys disponibles para debugging
          if (jsonData is Map) {
            print(
              '❌ Keys actuales en la respuesta: ${jsonData.keys.join(", ")}',
            );
            jsonData.forEach((key, value) {
              print('   - $key: ${value.runtimeType} = $value');
            });

            // Verificar si hay error explícito del backend
            if (jsonData.containsKey('error') ||
                jsonData.containsKey('detail') ||
                jsonData.containsKey('message')) {
              final errorMsg =
                  jsonData['error'] ??
                  jsonData['detail'] ??
                  jsonData['message'];
              print('❌ ERROR DEL BACKEND: $errorMsg');
              throw Exception('Error del servidor: $errorMsg');
            }
          }
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          // En lugar de fallar, mostrar toda la info para debugging
          final debugInfo = jsonData is Map
              ? 'Keys: ${jsonData.keys.join(", ")}\nDatos: $jsonData'
              : 'Respuesta raw: $jsonData';

          throw Exception(
            'El backend no devolvió una URL válida.\n\n'
            'DEBUGGING INFO:\n$debugInfo\n\n'
            'Por favor, envía esta información a soporte técnico.',
          );
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          final errorMsg = errorData['error'] ?? 'Datos de orden inválidos';
          print('❌ Error 400 - Bad Request: $errorMsg');
          print('   Detalles: $errorData');
          throw Exception('Error de validación: $errorMsg');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Datos de orden inválidos (Error 400)');
        }
      } else if (response.statusCode == 401) {
        print('❌ Error 401 - No autorizado: Token inválido o expirado');
        throw Exception(
          'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
        );
      } else if (response.statusCode == 404) {
        print('❌ Error 404 - No encontrado: Orden $orderId no existe');
        throw Exception(
          'La orden #$orderId no fue encontrada. '
          'Es posible que haya sido cancelada o no exista.',
        );
      } else if (response.statusCode == 500) {
        print('❌ Error 500 - Error del servidor:');
        print('   ${response.body}');
        throw Exception(
          'Error en el servidor de pagos. '
          'Por favor, intenta nuevamente en unos minutos. '
          'Si el problema persiste, contacta a soporte.',
        );
      } else {
        print('❌ Error HTTP inesperado: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception(
          'Error al procesar el pago (código ${response.statusCode}). '
          'Por favor, intenta nuevamente.',
        );
      }
    } on TimeoutException catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ TIMEOUT: ${e.message}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    } on SocketException catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ERROR DE RED: Sin conexión a internet');
      print('   Detalles: ${e.message}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      throw Exception(
        'No se pudo conectar al servidor de pagos. '
        'Verifica tu conexión a internet e intenta nuevamente.',
      );
    } on FormatException catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ERROR DE FORMATO: Respuesta JSON inválida');
      print('   Detalles: ${e.message}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      throw Exception(
        'Error al procesar la respuesta del servidor. '
        'Por favor, intenta nuevamente.',
      );
    } on Exception catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ EXCEPCIÓN: ${e.toString()}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ERROR INESPERADO: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      throw Exception(
        'Error inesperado al crear la sesión de pago. '
        'Por favor, intenta nuevamente.',
      );
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
      print('🚀 INICIO createOrderAndCheckout');

      // Paso 1: Crear orden desde carrito
      print('📋 PASO 1: Crear orden desde carrito');
      final order = await createOrderFromCart(
        token: token,
        shippingAddress: shippingAddress,
        shippingPhone: shippingPhone,
      );
      print('✅ PASO 1 COMPLETADO: Orden ID ${order.id} creada');

      // Paso 2: Crear sesión de Stripe
      print('💳 PASO 2: Crear sesión de Stripe para orden ${order.id}');
      final checkoutUrl = await createStripeCheckoutSession(
        token: token,
        orderId: order.id,
      );
      print('✅ PASO 2 COMPLETADO: URL obtenida');

      return checkoutUrl;
    } catch (e) {
      print('💥 EXCEPCIÓN en createOrderAndCheckout: $e');
      print('💥 Tipo de error: ${e.runtimeType}');
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
