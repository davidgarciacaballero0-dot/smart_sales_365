// lib/screens/admin/admin_dashboard_screen.dart

// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/analytics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartsales365/screens/admin/admin_product_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_category_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_brand_list_screen.dart';
// 1. IMPORTA LA NUEVA PANTALLA DE REPORTES
import 'package:smartsales365/screens/admin/admin_report_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  late Future<Map<String, dynamic>> _predictionsFuture;
  late Future<Map<String, dynamic>> _sentimentFuture;
  late Future<List<dynamic>> _associationsFuture;

  @override
  void initState() {
    super.initState();
    final String? token = context.read<AuthProvider>().accessToken;
    if (token != null) {
      _predictionsFuture = _analyticsService.getSalesPredictions(token);
      _sentimentFuture = _analyticsService.getSentimentAnalysis(token);
      _associationsFuture = _analyticsService.getProductAssociations(token);
    } else {
      _predictionsFuture = Future.error('Token no disponible');
      _sentimentFuture = Future.error('Token no disponible');
      _associationsFuture = Future.error('Token no disponible');
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
            // --- Sección de Reportes Dinámicos ---
            Text(
              'Reportes de IA',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            // 2. ¡NUEVO BOTÓN PARA REPORTES DINÁMICOS!
            Card(
              elevation: 2,
              color: Colors.blueGrey[800],
              child: ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  size: 30,
                  color: Colors.white,
                ),
                title: const Text(
                  'Generador de Reportes IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Usar lenguaje natural para crear reportes',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminReportScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Sección de Analíticas ---
            Text(
              'Dashboard de Analíticas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            Text(
              'Predicciones de Ventas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildPredictionsChart(),

            const SizedBox(height: 24),

            Text(
              'Análisis de Sentimiento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildSentimentChart(),

            const SizedBox(height: 24),

            Text(
              'Asociaciones de Productos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildAssociationsList(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- Sección de Gestión (sin cambios) ---
            Text(
              'Gestión de la Tienda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, size: 30),
                title: const Text('Gestionar Productos'),
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
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.category_outlined, size: 30),
                title: const Text('Gestionar Categorías'),
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
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.label_outline, size: 30),
                title: const Text('Gestionar Marcas'),
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

  // --- Gráfico de Predicciones (sin cambios) ---
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
              if (!snapshot.hasData ||
                  (snapshot.data!['predictions'] as List).isEmpty) {
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

  // --- Gráfico de Sentimiento (sin cambios) ---
  Widget _buildSentimentChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _sentimentFuture,
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
              if (!snapshot.hasData ||
                  snapshot.data!['sentiment_distribution'] == null) {
                return const Center(
                  child: Text('No hay datos de sentimiento.'),
                );
              }

              final Map<String, dynamic> distribution =
                  snapshot.data!['sentiment_distribution'];
              final double positive = (distribution['positive'] ?? 0)
                  .toDouble();
              final double neutral = (distribution['neutral'] ?? 0).toDouble();
              final double negative = (distribution['negative'] ?? 0)
                  .toDouble();
              final double total = positive + neutral + negative;

              if (total == 0) {
                return const Center(
                  child: Text('No hay reseñas para analizar.'),
                );
              }

              final List<PieChartSectionData> sections = [
                PieChartSectionData(
                  color: Colors.green,
                  value: positive,
                  title: '${(positive / total * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.grey,
                  value: neutral,
                  title: '${(neutral / total * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: negative,
                  title: '${(negative / total * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ];

              return Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.green, 'Positivo ($positive)'),
                      _buildLegendItem(Colors.grey, 'Neutral ($neutral)'),
                      _buildLegendItem(Colors.red, 'Negativo ($negative)'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // --- Lista de Asociaciones (sin cambios) ---
  Widget _buildAssociationsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<dynamic>>(
          future: _associationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar asociaciones:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No se encontraron asociaciones.'),
              );
            }

            final associations = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quienes compraron A, también compraron B:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...associations.map((rule) {
                  final String antecedents = (rule['antecedents'] as List).join(
                    ', ',
                  );
                  final String consequents = (rule['consequents'] as List).join(
                    ', ',
                  );
                  final double confidence = rule['confidence'] * 100;

                  return ListTile(
                    leading: const Icon(
                      Icons.shopping_cart_checkout,
                      color: Colors.blueGrey,
                    ),
                    title: Text('Si compran: $antecedents'),
                    subtitle: Text(
                      'También compran: $consequents\n(Confianza: ${confidence.toStringAsFixed(1)}%)',
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}
