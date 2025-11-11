// lib/screens/home_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/providers/tab_provider.dart';
import 'package:smartsales365/screens/cart_screen.dart';
import 'package:smartsales365/screens/catalog_screen.dart';
import 'package:smartsales365/screens/login_screen.dart';
import 'package:smartsales365/screens/order_history_screen.dart'; // Para el perfil

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Lista de widgets para las pestañas
  static final List<Widget> _widgetOptions = <Widget>[
    const CatalogScreen(),
    CartScreen(),
    const ProfileRouter(), // Pestaña 3 ahora es un router
  ];

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el TabProvider y CartProvider
    final tabProvider = context.watch<TabProvider>();
    final cartItemCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(tabProvider.selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Tienda',
          ),
          BottomNavigationBarItem(
            // --- BADGE (CONTADOR) DEL CARRITO ---
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Mi Cuenta',
          ),
        ],
        currentIndex: tabProvider.selectedIndex,
        selectedItemColor: Colors.blueGrey[800],
        onTap: (index) {
          // Cambia la pestaña usando el provider
          context.read<TabProvider>().changeTab(index);
        },
      ),
    );
  }
}

// --- WIDGET INTERNO PARA MANEJAR LA PESTAÑA DE PERFIL ---
class ProfileRouter extends StatelessWidget {
  const ProfileRouter({super.key});

  void _showLoginModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal sea alto
      builder: (modalContext) {
        // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
        // Le pasamos la función 'onLoginSuccess' al LoginScreen.
        // Usamos 'modalContext' para asegurarnos de que cerramos
        // el modal correcto.
        return LoginScreen(
          onLoginSuccess: () {
            Navigator.of(modalContext).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el estado de autenticación
    final authStatus = context.watch<AuthProvider>().status;

    // 1. Si está autenticado, muestra el historial de pedidos
    if (authStatus == AuthStatus.authenticated) {
      return const OrderHistoryScreen();
    }

    // 2. Si no está autenticado o está 'uninitialized',
    //    mostramos un "placeholder" y disparamos el modal de login
    //    Usamos addPostFrameCallback para mostrar el modal
    //    después de que el widget se haya construido.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginModal(context);
    });

    // Muestra un indicador de carga mientras se abre el modal
    return const Center(child: CircularProgressIndicator());
  }
}
