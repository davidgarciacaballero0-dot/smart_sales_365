// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartsales365/screens/admin/admin_product_list_screen.dart';
// 1. IMPORTA LAS NUEVAS PANTALLAS
import 'package:smartsales365/screens/admin/admin_category_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_brand_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  late Future<Map<String, dynamic>> _predictionsFuture;

  @override
  void initState() {
    super.initState();
    final String? token = context.read<AuthProvider>().accessToken;
    if (token != null) {
      _predictionsFuture = _analyticsService.getSalesPredictions(token);
    } else {
      _predictionsFuture = Future.error('Token no disponible');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dashboard de Analíticas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            Text(
              'Predicciones de Ventas (Próximos 7 días)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildPredictionsChart(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              'Gestión de la Tienda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Botón para gestionar productos (existente)
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, size: 30),
                title: const Text('Gestionar Productos'),
                subtitle: const Text('Ver, crear, editar y eliminar productos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProductListScreen(),
                    ),
                  );
                },
              ),
            ),

            // 2. NUEVO BOTÓN PARA CATEGORÍAS
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.category_outlined, size: 30),
                title: const Text('Gestionar Categorías'),
                subtitle: const Text(
                  'Ver, crear, editar y eliminar categorías',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCategoryListScreen(),
                    ),
                  );
                },
              ),
            ),

            // 3. NUEVO BOTÓN PARA MARCAS
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.label_outline, size: 30),
                title: const Text('Gestionar Marcas'),
                subtitle: const Text('Ver, crear, editar y eliminar marcas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminBrandListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Gráfico (sin cambios) ---
  Widget _buildPredictionsChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _predictionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar gráfico:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!['predictions'] == null) {
                return const Center(child: Text('No hay datos de predicción.'));
              }

              final List predictions = snapshot.data!['predictions'];
              final List<BarChartGroupData> barGroups = [];

              for (int i = 0; i < predictions.length; i++) {
                final predictionData = predictions[i];
                final double prediction = predictionData['prediction'];

                barGroups.add(
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: prediction,
                        color: Colors.blueGrey,
                        width: 15,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('Día ${value.toInt() + 1}');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
