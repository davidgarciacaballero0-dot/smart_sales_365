// lib/screens/order_history_screen.dart

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/order_provider.dart';
import 'package:intl/intl.dart';
// 1. IMPORTA LA NUEVA PANTALLA DE DETALLE
import 'package:smartsales365/screens/order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar órdenes al inicializar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final ordersProvider = context.read<OrderProvider>();
      ordersProvider.setToken(auth.token);
      await ordersProvider.loadInitial();
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
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (!provider.initialized && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async => provider.refresh(),
            child: provider.isLoading && provider.orders.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : provider.errorMessage != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error al cargar pedidos:\n${provider.errorMessage}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  )
                : provider.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Aún no has realizado ningún pedido.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: provider.orders.length,
                    itemBuilder: (context, index) {
                      final order = provider.orders[index];
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
                          onTap: () {
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
                  ),
          );
        },
      ),
    );
  }
}
