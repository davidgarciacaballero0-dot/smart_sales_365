// lib/providers/cart_provider.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smartsales365/models/cart_model.dart';
import 'package:smartsales365/services/cart_service.dart';

/// Provider del carrito que se sincroniza con el backend
/// Este reemplaza al CartProvider local antiguo
///
/// Características:
/// - Sincronización automática con backend
/// - Carrito persistente entre sesiones
/// - Validación de stock en tiempo real
/// - Cálculo de totales desde backend
class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasItems => _cart != null && _cart!.isNotEmpty;
  int get itemCount => _cart?.totalQuantity ?? 0; // ✅ Suma todas las cantidades
  double get totalPrice => _cart?.totalPrice ?? 0.0;

  // Flag para evitar múltiples cargas simultáneas
  bool _isLoadingCart = false;

  /// Carga el carrito desde el backend
  /// El backend automáticamente crea el carrito si no existe
  Future<void> loadCart(String token) async {
    // Evitar múltiples cargas simultáneas
    if (_isLoadingCart) {
      print('⏳ Carga de carrito ya en progreso, omitiendo...');
      return;
    }

    _isLoadingCart = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🛒 Cargando carrito desde backend...');
      _cart = await _cartService.getCart(token);
      print('✅ Carrito cargado: ${_cart!.items.length} items');
      print('💰 Total: \$${_cart!.totalPrice}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error al cargar carrito: $e');

      // Detectar token expirado y marcar para logout
      if (e.toString().contains('TOKEN_EXPIRED') ||
          e.toString().contains('401')) {
        _errorMessage = 'TOKEN_EXPIRED';
      } else {
        _errorMessage = 'Error al cargar el carrito: $e';
      }

      _isLoading = false;
      notifyListeners();
    } finally {
      _isLoadingCart = false;
    }
  }

  /// Añade un producto al carrito
  /// Si ya existe, incrementa su cantidad
  Future<bool> addToCart({
    required String token,
    required int productId,
    int quantity = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('➕ Añadiendo producto $productId (cantidad: $quantity)');
      _cart = await _cartService.addToCart(
        token: token,
        productId: productId,
        quantity: quantity,
      );
      print('✅ Producto añadido. Total items: ${_cart!.itemsCount}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error al añadir producto: $e');

      // Detectar token expirado
      if (e.toString().contains('TOKEN_EXPIRED') ||
          e.toString().contains('401')) {
        _errorMessage = 'TOKEN_EXPIRED';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualiza la cantidad de un item en el carrito
  Future<bool> updateQuantity({
    required String token,
    required int itemId,
    required int quantity,
  }) async {
    if (quantity < 0) {
      _errorMessage = 'La cantidad no puede ser negativa';
      notifyListeners();
      return false;
    }

    try {
      print('🔄 Actualizando item $itemId a cantidad $quantity');
      final updatedCart = await _cartService.updateCartItem(
        token: token,
        itemId: itemId,
        quantity: quantity,
      );

      // CORRECCIÓN: Actualizar el estado inmediatamente con la respuesta del backend
      _cart = updatedCart;
      _errorMessage = null;
      print(
        '✅ Cantidad actualizada. Items: ${_cart!.items.length}, Total items: ${_cart!.totalQuantity}, Precio total: \$${_cart!.totalPrice}',
      );
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error al actualizar cantidad: $e');

      // Detectar token expirado
      if (e.toString().contains('TOKEN_EXPIRED') ||
          e.toString().contains('401')) {
        _errorMessage = 'TOKEN_EXPIRED';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      notifyListeners();
      return false;
    }
  }

  /// Incrementa la cantidad de un item en 1
  Future<bool> incrementItem({
    required String token,
    required int itemId,
    required int currentQuantity,
  }) async {
    return await updateQuantity(
      token: token,
      itemId: itemId,
      quantity: currentQuantity + 1,
    );
  }

  /// Decrementa la cantidad de un item en 1
  /// Si llega a 0, elimina el item
  Future<bool> decrementItem({
    required String token,
    required int itemId,
    required int currentQuantity,
  }) async {
    if (currentQuantity <= 1) {
      return await removeItem(token: token, itemId: itemId);
    }
    return await updateQuantity(
      token: token,
      itemId: itemId,
      quantity: currentQuantity - 1,
    );
  }

  /// Elimina un item del carrito
  Future<bool> removeItem({required String token, required int itemId}) async {
    try {
      print('🗑️ Eliminando item $itemId del carrito');
      final updatedCart = await _cartService.removeFromCart(
        token: token,
        itemId: itemId,
      );

      // CORRECCIÓN: Actualizar el estado inmediatamente
      _cart = updatedCart;
      _errorMessage = null;
      print('✅ Item eliminado. Items restantes: ${_cart!.itemsCount}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error al eliminar item: $e');

      // Detectar token expirado
      if (e.toString().contains('TOKEN_EXPIRED') ||
          e.toString().contains('401')) {
        _errorMessage = 'TOKEN_EXPIRED';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      notifyListeners();
      return false;
    }
  }

  /// Vacía completamente el carrito
  Future<bool> clearCart(String token) async {
    try {
      print('🧹 Vaciando carrito...');
      final emptyCart = await _cartService.clearCart(token);

      // CORRECCIÓN: Actualizar el estado inmediatamente
      _cart = emptyCart;
      _errorMessage = null;
      print('✅ Carrito vaciado');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error al vaciar carrito: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Valida que el carrito esté listo para checkout
  /// Retorna mensaje de error si no es válido, null si está OK
  String? validateForCheckout() {
    if (_cart == null) {
      return 'El carrito no se ha cargado correctamente';
    }

    if (_cart!.items.isEmpty) {
      return 'El carrito está vacío';
    }

    if (_cart!.totalPrice <= 0) {
      return 'El total del carrito debe ser mayor a cero';
    }

    return null; // Carrito válido
  }

  /// Limpia el estado local (útil al hacer logout)
  void reset() {
    _cart = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
