// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/services/auth_provider.dart';

// Esta será la pantalla principal de la app (Fase 3 del plan)
// Por ahora, solo muestra un saludo y un botón de logout.
class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Leemos el usuario directamente desde el AuthProvider
    // Usamos 'watch' (el 'listen: true' por defecto) para que si
    // el usuario cambia, este widget se reconstruya.
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSales365'),
        actions: [
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              // Llamamos al método logout (listen: false porque está en un callback)
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Center(
        // Saludamos al usuario usando su nombre
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido, ${user?.username ?? 'Usuario'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Tu Rol: ${user?.roleName ?? 'N/A'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
