// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/providers/tab_provider.dart';
import 'package:smartsales365/screens/admin/admin_dashboard_screen.dart';
import 'package:smartsales365/screens/home_screen.dart';
import 'package:smartsales365/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          // CORRECCIÓN (Error 1): Usar parámetros nombrados
          create: (_) => CartProvider(authToken: null, initialItems: []),
          // CORRECCIÓN (Error 2): Usar parámetros nombrados
          update: (context, auth, previousCart) => CartProvider(
            authToken: auth.token,
            initialItems: previousCart == null ? [] : previousCart.items,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SmartSales365',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // CORRECCIÓN de error anterior (Paso 1):
        // Usar 'unknown' y 'loading'
        if (auth.status == AuthStatus.unknown ||
            auth.status == AuthStatus.loading) {
          return const SplashScreen();
        }

        if (auth.isAuthenticated) {
          if (auth.isAdmin) {
            return const AdminDashboardScreen();
          } else {
            return const HomeScreen();
          }
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
