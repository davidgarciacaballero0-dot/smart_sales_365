// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/catalog_screen.dart';
import 'package:smartsales365/screens/cart_screen.dart';
import 'package:smartsales365/screens/login_screen.dart';
// 1. IMPORTA LA NUEVA PANTALLA DE HISTORIAL
import 'package:smartsales365/screens/order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CatalogScreen(),
    const CartScreen(),
    const ProfileRouter(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Tienda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Mi Cuenta',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueGrey[800],
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

/// (La clase 'ProfileRouter' queda exactamente igual)
class ProfileRouter extends StatelessWidget {
  const ProfileRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.status == AuthStatus.authenticated) {
      return const UserProfileScreen();
    } else {
      return const LoginScreen();
    }
  }
}

/// -------------------------------------------
/// ¡AQUÍ ESTÁ EL CAMBIO!
/// (Actualizamos la pantalla de Perfil)
/// -------------------------------------------
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                '¡Bienvenido!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // 2. NUEVO BOTÓN PARA VER HISTORIAL DE PEDIDOS
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Mis Pedidos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                // 3. Navega a la nueva pantalla
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // (Aquí podemos añadir más botones, como "Editar Perfil", etc.)
            const Spacer(), // Ocupa todo el espacio disponible
            // 4. BOTÓN DE CERRAR SESIÓN (ahora al final)
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                authProvider.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
