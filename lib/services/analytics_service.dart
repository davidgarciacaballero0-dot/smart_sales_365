// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Importa el paquete de gráficos

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
          // Botón de Cerrar Sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();
              // El AuthWrapper en main.dart nos redirigirá al HomeScreen (invitado)
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

            // --- Tarjeta de Gráfico de Predicciones ---
            Text(
              'Predicciones de Ventas (Próximos 7 días)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildPredictionsChart(),

            // (Aquí añadiremos más tarjetas para CRUD y otros reportes)
          ],
        ),
      ),
    );
  }

  /// Construye el gráfico de predicciones
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

              // Extrae los datos de predicción
              final List predictions = snapshot.data!['predictions'];
              final List<BarChartGroupData> barGroups = [];

              for (int i = 0; i < predictions.length; i++) {
                final predictionData = predictions[i];
                // Tu backend devuelve {'day': 'YYYY-MM-DD', 'prediction': X}
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

              // Retorna el gráfico de barras
              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Muestra el día (1, 2, 3...)
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
