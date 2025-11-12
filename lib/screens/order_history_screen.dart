// lib/screens/order_history_screen.dart

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/order_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/order_service.dart';
import 'package:intl/intl.dart';
// 1. IMPORTA LA NUEVA PANTALLA DE DETALLE
import 'package:smartsales365/screens/order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  Future<List<Order>>? _ordersFuture;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para asegurar que el context esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CORRECCIÓN 1/1:
      // Cambiado de 'accessToken' a 'token'
      final String? token = context.read<AuthProvider>().token;

      if (token != null) {
        setState(() {
          _ordersFuture = _orderService.getOrders(token);
        });
      } else {
        setState(() {
          _ordersFuture = Future.error(
            'No se encontró el token de autenticación.',
          );
        });
      }
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('d \'de\' MMMM, yyyy', 'es_ES').format(date);
  }

  Color _getStatusColor(String status) {
    if (status == 'completed') {
      return Colors.green;
    } else if (status == 'pending') {
      return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Historial de Pedidos')),
      body: _ordersFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar pedidos:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aún no has realizado ningún pedido.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final orders = snapshot.data!;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'Pedido #${order.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha: ${_formatDate(order.createdAt)}'),
                            Text(
                              'Total: Bs. ${order.totalPrice.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  order.paymentStatus ?? 'pendiente',
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                // CORRECCIÓN: Manejar null con operador ??
                                'Estado: ${(order.paymentStatus ?? 'pendiente').toUpperCase()}',
                                style: TextStyle(
                                  color: _getStatusColor(
                                    order.paymentStatus ?? 'pendiente',
                                  ),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),

                        // 2. ¡AQUÍ ESTÁ EL CAMBIO!
                        onTap: () {
                          // Navega a la pantalla de detalle y pasa el objeto 'order'
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailScreen(order: order),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
