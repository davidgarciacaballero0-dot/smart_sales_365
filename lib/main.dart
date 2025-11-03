import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/home_screen.dart';
import 'package:smartsales365/screens/login_screen.dart';
import 'package:smartsales365/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Iniciamos el AuthProvider aquí para que toda la app lo conozca
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'SmartSales365',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const AuthWrapper(), // El punto de entrada es el Wrapper
        debugShowCheckedModeBanner: false,
      ),
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

    // Caso 1: Estamos verificando el auto-login (estado inicial)
    if (authProvider.status == AuthStatus.uninitialized) {
      return const SplashScreen(); // Muestra pantalla de carga
    }

    // Caso 2: Estamos autenticados
    if (authProvider.status == AuthStatus.authenticated) {
      return const HomeScreen(); // Muestra la app principal
    }

    // Caso 3: No estamos autenticados
    return const LoginScreen(); // Muestra el login
  }
}
