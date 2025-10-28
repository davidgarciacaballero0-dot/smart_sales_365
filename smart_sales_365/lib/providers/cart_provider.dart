// TODO Implement this library.
// lib/providers/cart_provider.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:smart_sales_365/models/cart_model.dart';
import 'package:smart_sales_365/services/cart_service.dart';
import 'package:smart_sales_365/models/cart_item_model.dart'; // Para tipo de retorno

// Estados posibles para las operaciones del carrito
enum CartStatus {
  idle, // Inicial o después de una operación exitosa/fallida
  loading, // Cargando el carrito inicial
  addingItem, // Añadiendo un item
  updatingItem, // Actualizando cantidad
  removingItem, // Eliminando un item
  error, // Ocurrió un error en la última operación
}

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  // --- Estado Interno ---
  Cart?
  _cart; // El carrito actual (puede ser null si no existe o no se ha cargado)
  CartStatus _status = CartStatus.idle;
  String _errorMessage = '';

  // --- Getters Públicos ---
  Cart? get cart => _cart;
  CartStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Getters de conveniencia
  List<CartItem> get items => _cart?.items ?? [];
  double get total => _cart?.total ?? 0.0;
  // Suma las cantidades de todos los items en el carrito
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  // Indica si alguna operación está en curso
  bool get isLoading =>
      _status != CartStatus.idle && _status != CartStatus.error;
  bool get hasError => _status == CartStatus.error;

  // --- Métodos ---

  // Cargar el carrito inicial (se puede llamar al iniciar sesión o al entrar a Home)
  Future<void> loadCart() async {
    // Si ya está realizando otra operación (que no sea la carga inicial), no hacer nada
    if (isLoading && _status != CartStatus.loading) return;

    _status = CartStatus.loading;
    _errorMessage = '';
    // No notificamos inmediatamente para evitar reconstrucciones innecesarias
    // notifyListeners();

    try {
      // Intenta obtener el carrito desde el servicio
      _cart = await _cartService.getCart();
      _status = CartStatus.idle; // Vuelve a idle si fue exitoso
      print('🛒 Carrito cargado/actualizado. Total: ${_cart?.total}');
    } on Exception catch (e) {
      // Manejo específico si el backend devuelve "Carrito no encontrado" (ej. 404)
      if (e.toString().contains('Carrito no encontrado')) {
        print('ℹ️ Creando carrito local vacío porque no existe en backend.');
        // Creamos un estado de carrito vacío localmente
        _cart = const Cart(
          id: -1,
          userId: -1,
          items: [],
          total: 0.0,
        ); // Carrito 'dummy' o placeholder
        _status = CartStatus.idle;
        _errorMessage = ''; // No lo tratamos como un error para el usuario
      } else {
        // Si es cualquier otro error (ej. de red, 500 del servidor)
        _cart =
            null; // O podríamos decidir mantener el carrito anterior si existía
        _status = CartStatus.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        print('❌ Error cargando carrito: $_errorMessage');
      }
    } finally {
      // Notifica a la UI sobre el resultado final (éxito, vacío local, o error)
      notifyListeners();
    }
  }

  // Añadir un item al carrito
  Future<bool> addItem(int productId, {int quantity = 1}) async {
    // Evita operaciones simultáneas si ya está cargando/modificando
    if (isLoading) return false;

    _status = CartStatus.addingItem;
    _errorMessage = '';
    notifyListeners(); // Notifica para mostrar feedback de carga (ej. un spinner en el botón)

    try {
      // Llama al servicio para añadir el item
      await _cartService.addItemToCart(
        productId: productId,
        quantity: quantity,
      );
      // Después de añadir exitosamente, recarga el estado completo del carrito
      await loadCart(); // loadCart se encargará de actualizar _status y notificar
      // Devuelve true si la recarga posterior no resultó en error
      return _status != CartStatus.error;
    } catch (e) {
      // Si addItemToCart o loadCart fallan
      _status = CartStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners(); // Notifica el error
      return false;
    }
  }

  // Actualizar la cantidad de un item
  Future<bool> updateItemQuantity(int itemId, int quantity) async {
    if (isLoading) return false;
    // Validación básica (el servicio también valida)
    if (quantity < 1) {
      _errorMessage = "La cantidad mínima es 1.";
      _status = CartStatus
          .error; // Podría ser un estado diferente para errores de validación
      notifyListeners();
      return false;
    }

    _status = CartStatus.updatingItem;
    _errorMessage = '';
    notifyListeners();

    try {
      // Llama al servicio para actualizar
      await _cartService.updateCartItem(itemId: itemId, quantity: quantity);
      // Recarga el carrito para obtener el nuevo total y estado
      await loadCart();
      return _status != CartStatus.error;
    } catch (e) {
      _status = CartStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Eliminar un item del carrito
  Future<bool> removeItem(int itemId) async {
    if (isLoading) return false;

    _status = CartStatus.removingItem;
    _errorMessage = '';
    notifyListeners();

    try {
      // Llama al servicio para eliminar
      await _cartService.removeCartItem(itemId: itemId);
      // Recarga el carrito
      await loadCart();
      return _status != CartStatus.error;
    } catch (e) {
      _status = CartStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Método para limpiar el estado local del carrito (útil al hacer logout)
  void clearLocalCart() {
    _cart = null; // Elimina los datos del carrito
    _status = CartStatus.idle; // Resetea el estado
    _errorMessage = ''; // Limpia cualquier error previo
    notifyListeners(); // Notifica a la UI para que se actualice (ej. contador a 0)
    print('🧹 Carrito local limpiado.');
  }
}
