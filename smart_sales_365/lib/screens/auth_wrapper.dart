// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';
import 'package:smart_sales_365/screens/home_screen.dart';
import 'package:smart_sales_365/screens/login_screen.dart';
import 'package:smart_sales_365/screens/splash_screen.dart';
// <-- CORRECCIÓN: Importar la nueva pantalla de admin
import 'package:smart_sales_365/screens/admin_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  // <-- CORRECCIÓN: Constructor actualizado a 'const super.key'
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 1. Mientras revisa el token, muestra SplashScreen
    if (authProvider.isLoading) {
      // SplashScreen debe tener un constructor const (ver Archivo 6)
      return const SplashScreen();
    }

    // 2. Si ESTÁ autenticado
    if (authProvider.isAuthenticated) {
      // <-- INICIO LÓGICA DE ROLES -->
      final user = authProvider.user;

      // Revisa el rol del usuario
      if (user != null && user.roleName == 'admin') {
        // 2a. Si es 'admin', va al Panel de Admin
        return const AdminDashboardScreen();
      } else {
        // 2b. Si es 'client' o cualquier otro, va al Home de Cliente
        return HomeScreen();
      }
      // <-- FIN LÓGICA DE ROLES -->
    }
    // 3. Si NO está autenticado, va al Login
    else {
      return LoginScreen();
    }
  }
}
