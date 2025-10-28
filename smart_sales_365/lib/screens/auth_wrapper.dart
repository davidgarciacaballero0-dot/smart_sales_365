// lib/screens/auth_wrapper.dart
// ignore_for_file: unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/screens/home_screen.dart';
import 'package:smart_sales_365/screens/login_screen.dart';
import 'package:smart_sales_365/screens/splash_screen.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch para escuchar los cambios en AuthProvider
    final authProvider = context.watch<AuthProvider>();

    // Decidimos qué pantalla mostrar
    switch (authProvider.authStatus) {
      case AuthStatus.authenticated:
        // Si está autenticado, vamos a Home
        return const HomeScreen();

      case AuthStatus.unauthenticated:
        // Si no está autenticado, vamos al Login
        return const LoginScreen();

      case AuthStatus.uninitialized:
      case AuthStatus.authenticating:
      case AuthStatus.registering:
      default:
        // Mientras carga, o en cualquier otro estado, mostramos el Splash
        return const SplashScreen();
    }
  }
}
