// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/admin/admin_brand_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_category_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_product_list_screen.dart';
import 'package:smartsales365/screens/admin/admin_report_screen.dart';
import 'package:smartsales365/screens/admin/admin_user_list_screen.dart';

// Convertimos el Dashboard en un StatelessWidget, ya no carga datos.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // CORRECCIÓN: El nombre correcto es .userProfile
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gestión del Sistema',
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
                  color: Colors.teal.shade700,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminReportScreen(),
                      ),
                    );
                  },
                ),
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
