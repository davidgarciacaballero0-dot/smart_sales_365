// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'), // <-- AÑADIDO CONST
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // <-- AÑADIDO CONST
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          )
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
