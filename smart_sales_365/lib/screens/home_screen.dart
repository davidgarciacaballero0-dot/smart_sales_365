// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sales_365/models/category_model.dart';
import 'package:smart_sales_365/providers/auth_provider.dart';
import 'package:smart_sales_365/providers/product_provider.dart';
import 'package:smart_sales_365/widgets/product_grid_item.dart';
// Asumo que crearás este archivo 'cart_badge.dart' en el siguiente paso
// Si causa error, coméntalo temporalmente.
import 'package:smart_sales_365/widgets/cart_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      _minPriceController.text = provider.filters['price__gte'] ?? '';
      _maxPriceController.text = provider.filters['price__lte'] ?? '';
      final categoryId = provider.filters['category'];
      if (categoryId != null && provider.categories.isNotEmpty) {
        _selectedCategory = provider.categories.firstWhere(
          (c) => c.id.toString() == categoryId,
          orElse: () => null,
        );
      }
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _showSortOptions(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.arrow_upward),
              title: Text('Precio: Más bajo a más alto'),
              onTap: () {
                provider.setFilter('ordering', 'price');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_downward),
              title: Text('Precio: Más alto a más bajo'),
              onTap: () {
                provider.setFilter('ordering', '-price');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.sort_by_alpha),
              title: Text('Nombre: A-Z'),
              onTap: () {
                provider.setFilter('ordering', 'name');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.sort_by_alpha),
              title: Text('Nombre: Z-A'),
              onTap: () {
                provider.setFilter('ordering', '-name');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilterOptions(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filtrar Productos',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      // --- CORRECCIÓN LINTER: 'value' por 'initialValue' ---
                      // (Nota: Si esto no funciona, lo revertiremos. Es por el linter.)
                      initialValue: _selectedCategory,
                      hint: Text('Seleccionar categoría'),
                      items: provider.categories.map((Category category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (Category? newValue) {
                        setModalState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            decoration: InputDecoration(
                              labelText: 'Precio Mín.',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            decoration: InputDecoration(
                              labelText: 'Precio Máx.',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          child: Text('Limpiar Filtros'),
                          onPressed: () {
                            _minPriceController.clear();
                            _maxPriceController.clear();
                            setModalState(() {
                              _selectedCategory = null;
                            });
                            provider.clearFilters();
                            Navigator.of(ctx).pop();
                          },
                        ),
                        ElevatedButton(
                          child: Text('Aplicar'),
                          onPressed: () {
                            provider.setFilter(
                              'price__gte',
                              _minPriceController.text,
                            );
                            provider.setFilter(
                              'price__lte',
                              _maxPriceController.text,
                            );
                            provider.setFilter(
                              'category',
                              _selectedCategory?.id.toString() ?? '',
                            );
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Catálogo'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
          ),

          const CartBadge(), // Esto dará error hasta que creemos cart_badge.dart

          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onChanged: (value) {
                      provider.setFilter('search', value);
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: provider.products.length,
                    itemBuilder: (ctx, i) =>
                        ProductGridItem(product: provider.products[i]),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
