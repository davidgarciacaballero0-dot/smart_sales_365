// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';
import 'package:smart_sales_365/providers/cart_provider.dart';
import 'package:smart_sales_365/providers/product_provider.dart';
import 'package:smart_sales_365/screens/auth_wrapper.dart';
import 'package:smart_sales_365/screens/login_screen.dart';
import 'package:smart_sales_365/screens/register_screen.dart';

void main() {
  runApp(const MyApp()); // <-- AÑADIDO CONST
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ProductProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'SmartSales365',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            scaffoldBackgroundColor: Colors.grey[100],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
          routes: {
            // No se usan activamente por el AuthWrapper, pero es bueno tenerlos
            '/login': (ctx) =>
                const LoginScreen(), // <-- AÑADIDO CONST (aunque LoginScreen no es const)
            '/register': (ctx) => const RegisterScreen(), // <-- AÑADIDO CONST
          },
        ),
      ),
    );
  }
}
