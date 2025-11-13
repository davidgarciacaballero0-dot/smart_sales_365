// lib/providers/order_provider.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smartsales365/models/order_model.dart';
import 'package:smartsales365/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  final List<Order> _orders = [];
  bool _initialized = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Order> get orders => List.unmodifiable(_orders);
  bool get isEmpty => _orders.isEmpty && !_isLoading && _errorMessage == null;
  bool get initialized => _initialized;

  void setToken(String? token) {
    if (_token != token) {
      _token = token;
      // Si cambia el token y ya estaba inicializado, recargar
      if (_initialized && _token != null) {
        refresh();
      }
    }
  }

  Future<void> loadInitial() async {
    if (_initialized) return; // evitar doble carga inicial
    await _fetchOrders();
    _initialized = true;
  }

  Future<void> refresh() async {
    await _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (_token == null) {
      _errorMessage = 'No autenticado';
      _orders.clear();
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _orderService.getOrders(_token!);
      _orders
        ..clear()
        ..addAll(list);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _orders.clear();
      notifyListeners();
    }
  }
}
