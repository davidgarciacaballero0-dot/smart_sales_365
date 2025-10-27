// lib/main.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/screens/home_screen.dart';
import 'package:smart_sales_365/screens/login_screen.dart';
import 'package:smart_sales_365/screens/register_screen.dart';
import 'package:smart_sales_365/services/auth_provider.dart';
import 'package:smart_sales_365/services/auth_wrapper.dart';

// Asumimos que estos archivos se crearán en los siguientes pasos
// Por ahora, 'auth_provider.dart' y 'auth_wrapper.dart' no existen.
// Para ejecutar esto, necesitarás crear esos archivos (siguientes pasos).
// O temporalmente puedes comentar las importaciones y cambiar 'home'.

void main() {
  runApp(
    // Envolvemos la App con MultiProvider para poder añadir
    // más providers (CartProvider, ProductProvider) en el futuro.
    MultiProvider(
      providers: [
        // Proveemos AuthProvider, que manejará el estado de autenticación.
        // Lo crearemos en el siguiente paso.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      debugShowCheckedModeBanner: false,

      // Configuración del Tema con Material 3
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // Color principal de la app
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey.shade50.withOpacity(0.5),
        ),
      ),

      // 'home' será nuestro widget "decisor" (AuthWrapper).
      // Este widget escuchará al AuthProvider y decidirá si mostrar
      // la pantalla de Login o la pantalla de Home.
      home: const AuthWrapper(),

      // Definimos las rutas para la navegación
      routes: {
        LoginScreen.routeName: (ctx) => const LoginScreen(),
        RegisterScreen.routeName: (ctx) => const RegisterScreen(),
        HomeScreen.routeName: (ctx) => const HomeScreen(),
      },
    );
  }
}
