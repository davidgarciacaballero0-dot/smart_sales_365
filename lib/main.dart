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
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Asegura que Flutter esté inicializado antes de inicializar locales
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa el formato de fechas para español
  await initializeDateFormatting('es_ES', null);

  runApp(
    MultiProvider(
      providers: [
        // CORRECCIÓN: Se llaman los constructores sin parámetros.
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
    // Aquí 'watch' es correcto para que reaccione a los cambios de estado
    final authProvider = context.watch<AuthProvider>();

    // Asumiendo que AuthProvider tiene un getter 'status' (como AuthStatus.uninitialized)
    // y un getter 'isAdmin'. (Lo verificaremos al ver los errores de auth_provider.dart)

    // CORRECCIÓN LÓGICA (Basada en tu auth_provider.dart):
    // Tu provider usa 'isAuthenticated' y 'isAdmin', pero también 'isLoading'
    // para el estado inicial. Vamos a usar 'isLoading' y 'isAuthenticated'.

    // (Ajuste basado en el auth_provider.dart que me enviaste)
    // Usaremos el 'status' que definiste en tu provider.

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

    // Por defecto (si no está autenticado), muestra HomeScreen (que mostrará el Login)
    return const HomeScreen();
  }
}
