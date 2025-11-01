// lib/screens/auth_wrapper.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';
import 'package:smart_sales_365/screens/admin_dashboard_screen.dart';
import 'package:smart_sales_365/screens/home_screen.dart';
import 'package:smart_sales_365/screens/login_screen.dart';
import 'package:smart_sales_365/screens/register_screen.dart';
import 'package:smart_sales_365/screens/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const SplashScreen();
    }

    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      if (user != null && user.roleName == 'admin') {
        return const AdminDashboardScreen();
      } else {
        return const HomeScreen(); // <-- AÑADIDO CONST
      }
    } else {
      return const LoginScreen(); // <-- AÑADIDO CONST
    }
  }
}
