// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';
import 'package:smart_sales_365/widgets/cart_item_widget.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_sales_365/services/payment_service.dart'; // Asegúrate de crear este servicio

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;

  Future<void> _handleCheckout() async {
    setState(() {
      _isLoading = true;
    });

    final cart = Provider.of<CartProvider>(context, listen: false);
    // --- CORRECCIÓN: Guardar el BuildContext ---
    final messenger = ScaffoldMessenger.of(context);
    // --- FIN DE LA CORRECCIÓN ---

    try {
      final sessionData =
          await _paymentService.createCheckoutSession(cart.items);
      final sessionId = sessionData['session_id'];

      final stripe = Stripe.instance;
      await stripe.redirectToCheckout(
        CheckoutOptions(
          sessionId: sessionId,
          mode: CheckoutMode.payment,
          successUrl: 'http://10.0.2.2:8000/success',
          cancelUrl: 'http://10.0.2.2:8000/cancel',
        ),
      );

      cart.clearCart();
    } catch (e) {
      // --- CORRECCIÓN: Usar el 'messenger' guardado ---
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al pagar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text('Tu carrito está vacío.',
                        style: TextStyle(fontSize: 18)),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return CartItemWidget(
                        item: item,
                        productId: cart.items.keys.toList()[i],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (cart.items.isEmpty || _isLoading)
                              ? null
                              : _handleCheckout,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          child: const Text('Pagar Ahora'),
                        ),
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
