// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/screens/catalog_screen.dart'; // ¡Importa tu catálogo!
import 'package:smartsales365/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Controla qué pestaña está activa (0 = Tienda)

  // Lista de pantallas para la navegación
  final List<Widget> _screens = [
    const CatalogScreen(), // Pestaña 0: La tienda
    const Text('Carrito (Próximamente)'), // Pestaña 1: El carrito
    const ProfileRouter(), // Pestaña 2: Perfil o Login
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

/// Este es un widget inteligente.
/// Revisa si el usuario está logueado.
/// Si SÍ lo está -> Muestra su perfil.
/// Si NO lo está -> Muestra la LoginScreen.
class ProfileRouter extends StatelessWidget {
  const ProfileRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // 'context.watch' hace que este widget se redibuje
    // si el estado de AuthProvider cambia (ej. al hacer login)
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.status == AuthStatus.authenticated) {
      // Si está logueado, muestra la pantalla de perfil
      return const UserProfileScreen();
    } else {
      // Si es invitado, muestra la pantalla de login
      return const LoginScreen();
    }
  }
}

/// Esta es la pantalla de Perfil del usuario (cuando SÍ está logueado)
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 'context.read' obtiene el provider solo para LLAMAR funciones
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¡Bienvenido!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            // (Aquí pondremos el historial de pedidos)
            ElevatedButton(
              onPressed: () {
                // Llama al logout de tu authProvider
                authProvider.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
