// lib/screens/home_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/providers/cart_provider.dart';
import 'package:smartsales365/providers/tab_provider.dart';
import 'package:smartsales365/screens/cart_screen.dart';
import 'package:smartsales365/screens/catalog_screen.dart';
import 'package:smartsales365/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Lista de widgets para las pestañas
  static final List<Widget> _widgetOptions = <Widget>[
    const CatalogScreen(),
    CartScreen(),
    const ProfileScreen(), // Siempre muestra perfil, el ProfileScreen maneja la autenticación
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
