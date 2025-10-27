// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';

// Pantalla simple que solo muestra un indicador de carga.
// Se mostrará al abrir la app mientras verificamos el token.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
