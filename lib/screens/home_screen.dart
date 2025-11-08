// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/tab_provider.dart';
// 1. IMPORTA EL CART_PROVIDER
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/screens/catalog_screen.dart';
import 'package:smartsales365/screens/cart_screen.dart';
import 'package:smartsales365/screens/login_screen.dart';
import 'package:smartsales365/screens/order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = [
    const CatalogScreen(),
    const CartScreen(),
    const ProfileRouter(),
  ];

  @override
  Widget build(BuildContext context) {
    // Escucha al TabProvider para saber qué pestaña mostrar
    final tabProvider = context.watch<TabProvider>();
    // 2. ESCUCHA AL CART_PROVIDER PARA OBTENER EL CONTEO
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: IndexedStack(index: tabProvider.selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          // --- Pestaña 1: Tienda (Sin cambios) ---
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Tienda',
          ),

          // --- 3. Pestaña 2: Carrito (ACTUALIZADA CON BADGE) ---
          BottomNavigationBarItem(
            // Ícono normal
            icon: Badge(
              // Muestra el total de items (ej. 1, 2, 3...)
              label: Text(cart.totalItemCount.toString()),
              // Solo muestra el badge si hay más de 0 items
              isLabelVisible: cart.totalItemCount > 0,
              // El ícono del carrito
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            // Ícono activo (cuando está seleccionada)
            activeIcon: Badge(
              label: Text(cart.totalItemCount.toString()),
              isLabelVisible: cart.totalItemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Carrito',
          ),

          // --- Pestaña 3: Mi Cuenta (Sin cambios) ---
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Mi Cuenta',
          ),
        ],
        currentIndex: tabProvider.selectedIndex,
        onTap: (index) {
          context.read<TabProvider>().changeTab(index);
        },
        selectedItemColor: Colors.blueGrey[800],
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// La clase 'ProfileRouter' no necesita cambios
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

// La clase 'UserProfileScreen' no necesita cambios
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
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Mis Pedidos'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Spacer(),
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
