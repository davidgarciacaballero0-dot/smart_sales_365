// lib/main.dart

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/catalog_screen.dart';

// (El router _router queda igual por ahora, lo actualizaremos después)
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const CatalogScreen()),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final String idParam = state.pathParameters['id'] ?? '0';
        final int productId = int.tryParse(idParam) ?? 0;
        return ProductDetailScreen(productId: productId);
      },
    ),
  ],
);

void main() {
  // 3. Envuelve la app en un 'ChangeNotifierProvider'
  runApp(
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
    return MaterialApp.router(
      title: 'SmartSales App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }
}
