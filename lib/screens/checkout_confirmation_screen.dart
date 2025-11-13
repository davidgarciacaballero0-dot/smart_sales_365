// lib/screens/checkout_confirmation_screen.dart

// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print, duplicate_ignore

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/payment_provider.dart';
import 'package:smartsales365/screens/order_history_screen.dart';
import 'package:smartsales365/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class CheckoutConfirmationScreen extends StatefulWidget {
  const CheckoutConfirmationScreen({super.key});

  @override
  State<CheckoutConfirmationScreen> createState() =>
      _CheckoutConfirmationScreenState();
}

class _CheckoutConfirmationScreenState
    extends State<CheckoutConfirmationScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll cada 5 segundos hasta que el estado sea PAGADO
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final paymentProvider = context.read<PaymentProvider>();
      final auth = context.read<AuthProvider>();
      final order = paymentProvider.lastOrder;

      // Detener polling si ya está pagado
      if (order?.status == 'PAGADO') {
        timer.cancel();
        return;
      }

      // Refrescar estado
      if (auth.token != null && order != null) {
        await paymentProvider.refreshLastOrder(token: auth.token!);
      }
    });
  }

  Future<void> _openStripeUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL inválida: $url'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copiar',
              textColor: Colors.white,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
              },
            ),
          ),
        );
        return;
      }

      // Intentar verificar si se puede abrir
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        // Abrir en navegador externo (Chrome, Safari, etc.)
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (opened) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Abriendo Stripe en tu navegador... '
                      'Completa el pago y vuelve a la app.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          throw Exception('launchUrl retornó false');
        }
      } else {
        throw Exception('canLaunchUrl retornó false');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error al abrir URL de Stripe: $e');
      print('   URL: $url');

      // Mostrar diálogo con opción de copiar URL
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('No se pudo abrir automáticamente'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No se pudo abrir el enlace de pago en tu navegador. '
                'Puedes copiar el enlace y pegarlo manualmente en Chrome u otro navegador.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace copiado al portapapeles'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar enlace'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _retrySession(BuildContext context) async {
    final paymentProvider = context.read<PaymentProvider>();
    final auth = context.read<AuthProvider>();

    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión expirada. Inicia sesión nuevamente.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await paymentProvider.retryStripeSession(token: auth.token!);

    if (paymentProvider.status == PaymentStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentProvider.errorMessage ?? 'No se pudo generar el enlace',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else if (paymentProvider.status == PaymentStatus.ready &&
        paymentProvider.checkoutUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nuevo enlace generado correctamente')),
      );
    }
  }

  Future<void> _refreshOrderStatus(BuildContext context) async {
    final paymentProvider = context.read<PaymentProvider>();
    final auth = context.read<AuthProvider>();

    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión expirada. Inicia sesión nuevamente.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await paymentProvider.refreshLastOrder(token: auth.token!);

    if (paymentProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de pago')),
      body: Consumer<PaymentProvider>(
        builder: (context, payment, _) {
          final order = payment.lastOrder;

          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay una orden reciente para confirmar.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            );
          }

          final url = payment.checkoutUrl;
          final orderService = OrderService();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Orden #${order.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Artículos: ${order.items.length}'),
                if (order.shippingAddress != null) ...[
                  const SizedBox(height: 4),
                  Text('Envío: ${order.shippingAddress}'),
                ],
                if (order.shippingPhone != null) ...[
                  const SizedBox(height: 4),
                  Text('Contacto: ${order.shippingPhone}'),
                ],

                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado del pago',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (order.status == 'PAGADO'
                                            ? Colors.green
                                            : order.status == 'PENDIENTE'
                                            ? Colors.orange
                                            : Colors.grey)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: order.status == 'PAGADO'
                                      ? Colors.green
                                      : order.status == 'PENDIENTE'
                                      ? Colors.orange
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _refreshOrderStatus(context),
                              icon: const Icon(Icons.sync),
                              label: const Text('Actualizar estado'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (payment.status == PaymentStatus.creatingSession)
                          const Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Creando sesión de pago...'),
                            ],
                          )
                        else if (payment.status == PaymentStatus.error)
                          Text(
                            payment.errorMessage ?? 'Error desconocido',
                            style: const TextStyle(color: Colors.red),
                          )
                        else if (url != null && url.isNotEmpty)
                          const Text('Enlace de pago listo')
                        else
                          const Text('Aún no hay enlace de pago disponible'),

                        const SizedBox(height: 12),
                        if (url != null && url.isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openStripeUrl(context, url),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Pagar ahora en Stripe'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: url),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Enlace copiado'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copiar enlace'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      payment.status ==
                                          PaymentStatus.creatingSession
                                      ? null
                                      : () => _retrySession(context),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar enlace'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  payment.status ==
                                      PaymentStatus.creatingSession
                                  ? null
                                  : () => _retrySession(context),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Generar enlace de pago'),
                            ),
                          ),
                        ],

                        if (order.status == 'PAGADO') ...[
                          const Divider(height: 24),
                          Text(
                            'Recibos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final receiptUrl = orderService
                                        .getReceiptHtmlUrl(order.id);
                                    final uri = Uri.parse(receiptUrl);
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('Ver Recibo (HTML)'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final pdfUrl = orderService
                                        .getReceiptPdfUrl(order.id);
                                    final uri = Uri.parse(pdfUrl);
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Descargar PDF'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Ver historial de pedidos'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.home),
                        label: const Text('Volver al inicio'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
