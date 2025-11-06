// lib/screens/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/services/api_service.dart';
import 'package:smartsales365/widgets/product_card.dart';

// Convertimos esta pantalla a un 'StatefulWidget' porque necesita
// mantener un estado (la lista de productos que viene de la API).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Un 'Future' que guardará el resultado de la llamada a la API
  late Future<List<Product>> _productsFuture;

  // Instancia de nuestro servicio de API
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // En cuanto la pantalla se "inicia", mandamos a llamar a la API
    // y guardamos el 'Future' en nuestra variable.
    _productsFuture = _apiService.getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartSales Catálogo')),
      // Usamos FutureBuilder: el widget perfecto para manejar estados
      // de 'cargando', 'error' y 'datos listos' de una API.
      body: FutureBuilder<List<Product>>(
        future: _productsFuture, // Le pasamos nuestro 'Future'
        builder: (context, snapshot) {
          // --- ESTADO 1: CARGANDO ---
          // 'snapshot.connectionState' nos dice cómo va la conexión
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              // Muestra un círculo de carga en el centro
              child: CircularProgressIndicator(),
            );
          }

          // --- ESTADO 2: ERROR ---
          // 'snapshot.hasError' nos dice si el Future falló
          if (snapshot.hasError) {
            return Center(
              // Muestra el mensaje de error. 'snapshot.error' tiene el error.
              child: Text(
                'Error al cargar productos: \n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // --- ESTADO 3: ÉXITO (DATOS LISTOS) ---
          // 'snapshot.hasData' nos dice si el Future se completó con datos
          if (snapshot.hasData) {
            // Guardamos la lista de productos que llegó
            final products = snapshot.data!;

            // Si la lista está vacía
            if (products.isEmpty) {
              return const Center(child: Text('No hay productos disponibles.'));
            }

            // Si hay datos, ¡construimos la cuadrícula!
            // Usamos GridView.builder para optimizar listas largas
            return GridView.builder(
              padding: const EdgeInsets.all(10.0),
              // 'gridDelegate' define cómo será la cuadrícula
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columnas
                crossAxisSpacing: 10, // Espacio horizontal entre tarjetas
                mainAxisSpacing: 10, // Espacio vertical entre tarjetas
                childAspectRatio:
                    0.75, // Proporción (ancho / alto) de la tarjeta
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                // Por cada producto en la lista, creamos una ProductCard
                return ProductCard(product: product);
                // ¡Punto clave! En el futuro, haremos que esta tarjeta sea
                // "tocable" (con un InkWell o GestureDetector) para navegar
                // a la pantalla de detalle del producto.
              },
            );
          }

          // Estado por defecto (no debería pasar, pero es bueno tenerlo)
          return const Center(child: Text('Iniciando...'));
        },
      ),
    );
  }
}
