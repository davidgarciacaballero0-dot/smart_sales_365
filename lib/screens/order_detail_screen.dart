// lib/screens/order_detail_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:smartsales365/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:smartsales365/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  String _formatDate(DateTime date) {
    return DateFormat('d \'de\' MMMM, yyyy - hh:mm a', 'es_ES').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${order.id}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Resumen del Pedido ---
              Text(
                'Resumen del Pedido',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('ID del Pedido:', '#${order.id}'),
                      _buildSummaryRow('Fecha:', _formatDate(order.createdAt)),
                      _buildSummaryRow(
                        'Estado del Pago:',
                        (order.paymentStatus ?? 'pendiente').toUpperCase(),
                        statusColor:
                            (order.paymentStatus ?? 'pendiente') == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      _buildSummaryRow(
                        'Total Pagado:',
                        'Bs. ${order.totalPrice.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Productos en el Pedido ---
              Text(
                'Productos (${order.items.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Image.network(
                        item.product.image ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          );
                        },
                      ),
                      title: Text(item.product.name),
                      subtitle: Text(
                        'Precio: Bs. ${item.price.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        '${item.quantity}x',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Botones de recibo (HTML y PDF)
              if (order.status == 'PAGADO') ...[
                Text('Recibos', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Ver Recibo (HTML)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueGrey[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final orderService = OrderService();
                          final receiptUrl = orderService.getReceiptHtmlUrl(
                            order.id,
                          );
                          final uri = Uri.parse(receiptUrl);
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Descargar PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final orderService = OrderService();
                          final pdfUrl = orderService.getReceiptPdfUrl(
                            order.id,
                          );
                          final uri = Uri.parse(pdfUrl);
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar (sin cambios)
  Widget _buildSummaryRow(
    String title,
    String value, {
    Color? statusColor,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: statusColor,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
