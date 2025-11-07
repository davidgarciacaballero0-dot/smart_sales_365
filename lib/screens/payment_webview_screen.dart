// lib/screens/payment_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url; // Recibe la 'checkout_url'

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            // 4. ¡Detecta si el pago fue exitoso o cancelado!
            // Tu backend (en 'CreateOrderView') define 'success_url' y 'cancel_url'.
            // Cuando Stripe redirige a estas URLs, lo detectamos aquí.

            // NOTA: Debes cambiar estas URLs por las que tu app usará.
            // Por ahora, usaremos las de ejemplo del frontend web.
            const String successUrl =
                'https://smartsales-frontend.onrender.com/checkout-success';
            const String cancelUrl =
                'https://smartsales-frontend.onrender.com/checkout-cancel';

            if (url.startsWith(successUrl)) {
              Navigator.of(
                context,
              ).pop('success'); // Vuelve a la app con "éxito"
            } else if (url.startsWith(cancelUrl)) {
              Navigator.of(
                context,
              ).pop('cancel'); // Vuelve a la app con "cancelado"
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // Carga la URL de Stripe
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Pago Seguro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop('cancel'),
        ),
      ),
      // Muestra la web y un indicador de carga encima
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
