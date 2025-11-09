// lib/screens/cart_screen.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
// 1. Importa los nuevos servicios y pantallas
import 'package:smartsales365/services/order_service.dart';
import 'package:smartsales365/screens/payment_webview_screen.dart';

import '../providers/tab_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // 2. Estado de carga para el botón de Pagar
  bool _isCreatingOrder = false;

  // 3. Método principal para manejar el proceso de pago
  Future<void> _handlePayment() async {
    // 4. Obtiene los providers (con 'listen: false' para usar en métodos)
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orderService = OrderService();

    // 5. ¡REQUERIMIENTO CLAVE! Verifica si el usuario está logueado
    // CORRECCIÓN 1/3 (de la lista de errores):
    // Tu AuthProvider usa 'status'
    if (auth.status != AuthStatus.authenticated) {
      _showLoginRequiredDialog();
      return;
    }

    // 6. Muestra el indicador de carga en el botón
    setState(() {
      _isCreatingOrder = true;
    });

    try {
      // 7. Llama al servicio para crear el pedido
      // CORRECCIÓN 2/3 (de la lista de errores):
      // Cambiado de 'accessToken' a 'token'
      final String token = auth.token!; // Sabemos que no es nulo
      final String checkoutUrl = await orderService.createOrder(token, cart);

      // 8. Navega a la pantalla WebView con la URL de Stripe
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(url: checkoutUrl),
        ),
      );

      // 9. Maneja la respuesta del WebView
      if (result == 'success' && mounted) {
        cart.clearCart(); // Limpia el carrito
        _showPaymentSuccessDialog();
      } else if (result == 'cancel' && mounted) {
        _showPaymentCancelDialog();
      }
    } catch (e) {
      // 10. Muestra un error si la creación del pedido falla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear el pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 11. Oculta el indicador de carga
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  // --- Widgets Auxiliares (Diálogos) ---
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inicio de Sesión Requerido'),
        content: const Text('Debes iniciar sesión para poder comprar.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Iniciar Sesión'),
            onPressed: () {
              Navigator.of(context).pop();
              // (Aquí podríamos navegar a la pestaña "Mi Cuenta",
              // pero por ahora solo cerramos el diálogo)

              // CORRECCIÓN 3/3 (Lógica):
              // Vamos a cambiar a la pestaña de "Mi Cuenta"
              context.read<TabProvider>().changeTab(2);
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Pago Exitoso!'),
        content: const Text('Tu pedido ha sido procesado correctamente.'),
        actions: [
          TextButton(
            child: const Text('Genial'),
            onPressed: () {
              Navigator.of(context).pop();
              // Lógica mejorada: Llévalo a ver sus pedidos
              context.read<TabProvider>().changeTab(2);
              // (El ProfileRouter lo dirigirá a UserProfileScreen
              // donde podrá ver sus pedidos)
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentCancelDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El pago fue cancelado.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 12. Usamos 'watch' aquí para que la lista se actualice
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi Carrito',
          style: TextStyle(
            color: Colors.blueGrey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío.',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      return ListTile(
                        leading: Image.network(
                          cartItem.product.image ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50);
                          },
                        ),
                        title: Text(cartItem.product.name),
                        subtitle: Text(
                          'Bs. ${cartItem.product.price.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cartItem.quantity}x',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                context.read<CartProvider>().removeFromCart(
                                  cartItem.product.id,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // --- TOTAL Y BOTÓN DE PAGO ---
                Container(
                  padding: const EdgeInsets.all(16.0).copyWith(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${cart.totalItemCount} productos):',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Bs. ${cart.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blueGrey[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          // 13. Conecta el botón al método _handlePayment
                          //    Deshabilita si ya está cargando
                          onPressed: _isCreatingOrder ? null : _handlePayment,
                          child: _isCreatingOrder
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Ir a Pagar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
