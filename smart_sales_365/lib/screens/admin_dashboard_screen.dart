// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  // CORRECCIÓN: Constructor actualizado a 'const super.key'
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Hacemos logout y el AuthWrapper nos redirigirá
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          '¡Bienvenido, Administrador!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
