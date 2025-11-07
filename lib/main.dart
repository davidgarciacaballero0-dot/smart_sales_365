// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/screens/home_screen.dart';
import 'package:smartsales365/screens/splash_screen.dart';
// 1. IMPORTA LA NUEVA PANTALLA DE ADMIN
import 'package:smartsales365/screens/admin/admin_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
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

// 2. ¡AQUÍ ESTÁ LA LÓGICA DE REDIRECCIÓN!
// Este Widget ahora comprueba el rol del usuario.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Caso 1: Aún estamos revisando el token guardado
    if (authProvider.status == AuthStatus.uninitialized) {
      return const SplashScreen();
    }

    // Caso 2: El usuario SÍ está autenticado
    if (authProvider.status == AuthStatus.authenticated) {
      // 3. Revisa si es Admin
      if (authProvider.isAdmin) {
        // Si es Admin -> Muestra el Dashboard de Admin
        return const AdminDashboardScreen();
      } else {
        // Si es Cliente -> Muestra la Tienda (HomeScreen)
        return const HomeScreen();
      }
    }

    // Caso 3: El usuario NO está autenticado (es invitado)
    // Muestra la Tienda (HomeScreen)
    return const HomeScreen();
  }
}
