// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
// 1. IMPORTA EL NUEVO TAB PROVIDER
import 'package:smartsales365/providers/tab_provider.dart';
import 'package:smartsales365/screens/home_screen.dart';
import 'package:smartsales365/screens/splash_screen.dart';
import 'package:smartsales365/screens/admin/admin_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        // 2. AÑADE EL TAB PROVIDER
        ChangeNotifierProvider(create: (context) => TabProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSales365',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.status == AuthStatus.uninitialized) {
      return const SplashScreen();
    }
    if (authProvider.status == AuthStatus.authenticated) {
      if (authProvider.isAdmin) {
        return const AdminDashboardScreen();
      } else {
        return const HomeScreen();
      }
    }
    return const HomeScreen();
  }
}
