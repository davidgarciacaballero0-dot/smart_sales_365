// lib/providers/payment_provider.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smartsales365/models/order_model.dart';
import 'package:smartsales365/services/order_service.dart';
import 'package:smartsales365/providers/cart_provider.dart';

enum PaymentStatus {
  idle,
  validatingCart,
  creatingOrder,
  creatingSession,
  ready,
  error,
}

class PaymentProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  PaymentStatus _status = PaymentStatus.idle;
  String? _errorMessage;
  Order? _lastOrder;
  String? _checkoutUrl;

  PaymentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Order? get lastOrder => _lastOrder;
  String? get checkoutUrl => _checkoutUrl;
  bool get isProcessing =>
      _status != PaymentStatus.idle &&
      _status != PaymentStatus.ready &&
      _status != PaymentStatus.error;

  void reset() {
    _status = PaymentStatus.idle;
    _errorMessage = null;
    _lastOrder = null;
    _checkoutUrl = null;
    notifyListeners();
  }

  Future<String?> processCheckout({
    required String token,
    required CartProvider cartProvider,
    required String shippingAddress,
    required String shippingPhone,
  }) async {
    // Validación inicial
    _status = PaymentStatus.validatingCart;
    _errorMessage = null;
    notifyListeners();

    // Recargar carrito para estado fresco
    await cartProvider.loadCart(token);
    final validationError = cartProvider.validateForCheckout();
    if (validationError != null) {
      _status = PaymentStatus.error;
      _errorMessage = validationError;
      notifyListeners();
      return null;
    }

    try {
      _status = PaymentStatus.creatingOrder;
      notifyListeners();
      final order = await _orderService.createOrderFromCart(
        token: token,
        shippingAddress: shippingAddress,
        shippingPhone: shippingPhone,
      );
      _lastOrder = order;

      _status = PaymentStatus.creatingSession;
      notifyListeners();
      final url = await _orderService.createStripeCheckoutSession(
        token: token,
        orderId: order.id,
      );
      _checkoutUrl = url;
      _status = PaymentStatus.ready;
      notifyListeners();

      // Carrito debería haberse vaciado por backend tras crear la orden
      await cartProvider.loadCart(token);
      return url;
    } catch (e) {
      _status = PaymentStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Reintenta crear solo la sesión de Stripe sobre la última orden creada
  /// No crea una nueva orden. Requiere token válido y _lastOrder existente
  Future<String?> retryStripeSession({required String token}) async {
    if (_lastOrder == null) {
      _errorMessage = 'No hay una orden previa para reintentar el pago.';
      _status = PaymentStatus.error;
      notifyListeners();
      return null;
    }

    try {
      _status = PaymentStatus.creatingSession;
      _errorMessage = null;
      _checkoutUrl = null;
      notifyListeners();

      final url = await _orderService.createStripeCheckoutSession(
        token: token,
        orderId: _lastOrder!.id,
      );

      _checkoutUrl = url;
      _status = PaymentStatus.ready;
      notifyListeners();
      return url;
    } catch (e) {
      _status = PaymentStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Refresca los datos de la última orden desde el backend
  /// Útil para verificar cambios de estado tras pago (webhook Stripe)
  Future<Order?> refreshLastOrder({required String token}) async {
    if (_lastOrder == null) {
      _errorMessage = 'No hay una orden para actualizar.';
      notifyListeners();
      return null;
    }

    try {
      final updated = await _orderService.getOrderById(
        token: token,
        orderId: _lastOrder!.id,
      );
      _lastOrder = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
