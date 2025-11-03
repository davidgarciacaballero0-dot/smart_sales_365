import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart'; // Ajusta la ruta

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              authProvider.logout(); // Llama al logout
            },
          ),
        ],
      ),
      body: const Center(child: Text('¡Bienvenido! Fase 1 Completada.')),
    );
  }
}
