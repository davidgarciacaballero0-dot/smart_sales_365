// lib/widgets/product_filter_drawer.dart

import 'package:flutter/material.dart';
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';

// Definimos un objeto simple para pasar los filtros
class ProductFilters {
  final int? categoryId;
  final int? brandId;
  final double? minPrice;
  final double? maxPrice;

  ProductFilters({this.categoryId, this.brandId, this.minPrice, this.maxPrice});
}

class ProductFilterDrawer extends StatefulWidget {
  // Recibe los filtros actualmente aplicados desde la pantalla del catálogo
  final ProductFilters currentFilters;

  // Callback para devolver los nuevos filtros seleccionados
  final Function(ProductFilters) onApplyFilters;

  // Callback para limpiar filtros
  final VoidCallback clearFilters;

  // Listas de categorías y marcas
  final List<Category> allCategories;
  final List<Brand> allBrands;

  const ProductFilterDrawer({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
    required this.allCategories,
    required this.allBrands,
    required this.clearFilters,
  });

  @override
  State<ProductFilterDrawer> createState() => _ProductFilterDrawerState();
}

class _ProductFilterDrawerState extends State<ProductFilterDrawer> {
  // Estado interno del Drawer para guardar selecciones temporales
  int? _selectedCategoryId;
  int? _selectedBrandId;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializa el estado del drawer con los filtros que ya estaban aplicados
    _selectedCategoryId = widget.currentFilters.categoryId;
    _selectedBrandId = widget.currentFilters.brandId;
    if (widget.currentFilters.minPrice != null) {
      _minPriceController.text = widget.currentFilters.minPrice.toString();
    }
    if (widget.currentFilters.maxPrice != null) {
      _maxPriceController.text = widget.currentFilters.maxPrice.toString();
    }
  }

  /// Devuelve los filtros seleccionados a la pantalla del catálogo
  void _apply() {
    final filters = ProductFilters(
      categoryId: _selectedCategoryId,
      brandId: _selectedBrandId,
      minPrice: double.tryParse(_minPriceController.text),
      maxPrice: double.tryParse(_maxPriceController.text),
    );
    widget.onApplyFilters(filters);
    Navigator.of(context).pop(); // Cierra el drawer
  }

  /// Limpia todos los filtros y cierra
  void _clear() {
    setState(() {
      _selectedCategoryId = null;
      _selectedBrandId = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    widget.clearFilters(); // Usa el callback del widget
  }

  @override
  Widget build(BuildContext context) {
    // Usar las listas que ya fueron pasadas como parámetros
    final List<Category> categories = widget.allCategories;
    final List<Brand> brands = widget.allBrands;

    return Drawer(
      child: Column(
        children: [
          // --- Cabecera ---
          AppBar(
            title: const Text('Filtros'),
            automaticallyImplyLeading: false, // Oculta el botón de "atrás"
            actions: [
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'Limpiar filtros',
                onPressed: _clear,
              ),
            ],
          ),

          // --- Contenido de Filtros (con scroll) ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Filtro de Precio ---
                  Text(
                    'Precio (Bs.)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Mínimo',
                            prefixText: 'Bs. ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            prefixText: 'Bs. ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // --- Filtro de Categoría ---
                  Text(
                    'Categoría',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  // Usamos 'Wrap' para que las categorías fluyan en chips
                  Wrap(
                    spacing: 8.0,
                    children: categories.map((category) {
                      final isSelected = _selectedCategoryId == category.id;
                      return ChoiceChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? category.id : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32),

                  // --- Filtro de Marca ---
                  Text('Marca', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8.0,
                    children: brands.map((brand) {
                      final isSelected = _selectedBrandId == brand.id;
                      return ChoiceChip(
                        label: Text(brand.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBrandId = selected ? brand.id : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // --- Botón de Aplicar (fijo abajo) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50), // Ancho completo
              ),
              onPressed: _apply,
              child: const Text('Aplicar Filtros'),
            ),
          ),
        ],
      ),
    );
  }
}
