// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/admin/admin_brand_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_category_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_product_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_report_screen.dart';
import 'package:smartsales365/services/analytics_service.dart';

// 1. IMPORTACIÓN CORREGIDA
import 'package:smartsales365/screens/admin/charts/association_chart.dart';
import 'package:smartsales365/screens/admin/charts/prediction_chart.dart';
import 'package:smartsales365/screens/admin/charts/sentiment_chart.dart';

// 2. IMPORTACIÓN AÑADIDA
import 'package:smartsales365/screens/admin/admin_user_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic> _predictions = {};
  Map<String, dynamic> _sentiments = {};
  List<dynamic> _associations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token no disponible');
      }

      final predictionsData = _analyticsService.getSalesPredictions(token);
      final sentimentsData = _analyticsService.getSentimentAnalysis(token);
      final associationsData = _analyticsService.getProductAssociations(token);

      final results = await Future.wait([
        predictionsData,
        sentimentsData,
        associationsData,
      ]);

      if (mounted) {
        setState(() {
          _predictions = results[0] as Map<String, dynamic>;
          _sentiments = results[1] as Map<String, dynamic>;
          _associations = results[2] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar analíticas: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Panel de ${authProvider.userProfile?.username ?? 'Admin'}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Analíticas IA',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : Column(
                      children: [
                        _buildChartCard(
                          'Predicción de Ventas (Próximos 7 días)',
                          PredictionChart(data: _predictions),
                        ),
                        _buildChartCard(
                          'Análisis de Sentimiento (Reseñas)',
                          SentimentChart(data: _sentiments),
                        ),
                        _buildChartCard(
                          'Asociación de Productos (IA)',
                          AssociationChart(data: _associations),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              Text(
                'Gestión de Contenido',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'Productos',
                    icon: Icons.store,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminProductListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Categorías',
                    icon: Icons.category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminCategoryListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Marcas',
                    icon: Icons.branding_watermark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminBrandListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Reportes IA',
                    icon: Icons.analytics,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminReportScreen(),
                        ),
                      );
                    },
                  ),

                  // 3. BOTÓN AÑADIDO
                  _buildDashboardCard(
                    context,
                    title: 'Usuarios',
                    icon: Icons.people,
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUserListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: color != null
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color != null ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
