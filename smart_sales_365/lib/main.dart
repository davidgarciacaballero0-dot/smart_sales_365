// lib/main.dart
// ignore_for_file: deprecated_member_use

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:smart_sales_365/screens/auth_wrapper.dart';
import 'package:smart_sales_365/screens/login_screen.dart';
import 'package:smart_sales_365/screens/register_screen.dart';
import 'package:smart_sales_365/screens/home_screen.dart';
import 'package:smart_sales_365/screens/product_detail_screen.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';
import 'package:smart_sales_365/providers/product_provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';

void main() {
  runApp(
    // MultiProvider permite registrar múltiples providers
    MultiProvider(
      providers: [
        // Provider para manejar la autenticación
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Provider para manejar los productos
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        // Provider para manejar el carrito
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // Puedes añadir más providers aquí en el futuro
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
      debugShowCheckedModeBanner: false, // Oculta la cinta de debug
      // Configuración del Tema con Material 3
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // Color principal
          brightness: Brightness.light,
        ),
        // Estilo para los campos de texto
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey.shade50.withOpacity(0.5),
        ),
      ),

      // Widget inicial que decide si mostrar Login o Home
      home: const AuthWrapper(),

      // Definición de las rutas nombradas para la navegación
      routes: {
        LoginScreen.routeName: (ctx) => const LoginScreen(),
        RegisterScreen.routeName: (ctx) => const RegisterScreen(),
        HomeScreen.routeName: (ctx) => const HomeScreen(),
        ProductDetailScreen.routeName: (ctx) => const ProductDetailScreen(),
        // Añadiremos la ruta para CartScreen más adelante
      },
    );
  }
}
