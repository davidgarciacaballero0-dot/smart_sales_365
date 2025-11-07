// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
// 1. IMPORTA EL NUEVO CART PROVIDER
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/screens/home_screen.dart';
import 'package:smartsales365/screens/splash_screen.dart';

void main() {
  runApp(
    // 2. CAMBIA A 'MultiProvider' para manejar varios providers
    MultiProvider(
      providers: [
        // El AuthProvider que ya tenías
        ChangeNotifierProvider(create: (context) => AuthProvider()),

        // El nuevo CartProvider que acabamos de crear
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: const MyApp(), // El hijo es tu app
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

// 3. TU 'AuthWrapper' QUEDA EXACTAMENTE IGUAL
// (No es necesario copiarlo, solo asegúrate de que esté)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.status == AuthStatus.uninitialized) {
      return const SplashScreen();
    }

    if (authProvider.status == AuthStatus.authenticated ||
        authProvider.status == AuthStatus.unauthenticated) {
      return const HomeScreen();
    }

    return const SplashScreen();
  }
}
