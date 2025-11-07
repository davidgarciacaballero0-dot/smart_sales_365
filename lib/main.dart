// lib/main.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/home_screen.dart';
import 'package:smartsales365/screens/login_screen.dart';
import 'package:smartsales365/screens/splash_screen.dart';

void main() {
  runApp(
    // Envolvemos toda la app en el AuthProvider para que
    // cualquier widget pueda escuchar el estado de autenticación.
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
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
      // El 'home' de la app es el AuthWrapper.
      // Este widget es el "portero" que decide qué mostrar.
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Este Widget es el "vigilante" de la autenticación.
// Decide qué pantalla mostrar basado en el AuthProvider.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    // Usamos el 'status' (con 'getter') que definimos en el provider

    // Caso 1: Estamos verificando el auto-login (estado inicial)
    // El provider acaba de ser creado y está revisando si hay un token guardado.
    if (authProvider.status == AuthStatus.uninitialized) {
      return const SplashScreen(); // Muestra pantalla de carga
    }

    // Caso 2: ¡EL CAMBIO CLAVE!
    // Si ya sabemos el estado (está autenticado O NO está autenticado),
    // mandamos al usuario a la HomeScreen.
    // La HomeScreen se encargará de mostrar el catálogo a los invitados
    // y el perfil/login en la pestaña "Mi Cuenta".
    if (authProvider.status == AuthStatus.authenticated ||
        authProvider.status == AuthStatus.unauthenticated) {
      return const HomeScreen();
    }

    // Caso 3: (Respaldo) Si por alguna razón el estado es 'loading' u otro,
    // mostramos la pantalla de carga por defecto.
    return const SplashScreen();
  }
}
