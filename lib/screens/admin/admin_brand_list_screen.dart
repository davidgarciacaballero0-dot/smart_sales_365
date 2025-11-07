// lib/screens/admin/admin_brand_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/category_brand_service.dart';

class AdminBrandListScreen extends StatefulWidget {
  const AdminBrandListScreen({super.key});

  @override
  State<AdminBrandListScreen> createState() => _AdminBrandListScreenState();
}

class _AdminBrandListScreenState extends State<AdminBrandListScreen> {
  final CategoryBrandService _service = CategoryBrandService();
  late Future<List<Brand>> _future;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _future = _service.getBrands();
    });
  }

  Future<void> _showFormDialog({Brand? brand}) async {
    final _nameController = TextEditingController(text: brand?.name);
    final _descriptionController = TextEditingController(
      text: brand?.description,
    );
    final _formKey = GlobalKey<FormState>();

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(brand == null ? 'Crear Marca' : 'Editar Marca'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'name': _nameController.text,
                    'description': _descriptionController.text,
                  });
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final String? token = context.read<AuthProvider>().accessToken;
      if (token == null) return;

      try {
        if (brand == null) {
          await _service.createBrand(token, result);
        } else {
          await _service.updateBrand(token, brand.id, result);
        }
        _fetchData(); // Refresca la lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    final bool didConfirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Eliminación'),
            content: const Text('¿Estás seguro de que quieres eliminar esto?'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (didConfirm && mounted) {
      final String? token = context.read<AuthProvider>().accessToken;
      if (token == null) return;
      try {
        await _service.deleteBrand(token, id);
        _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Marcas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Brand>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final brand = items[index];
              return ListTile(
                title: Text(brand.name),
                subtitle: Text(brand.description ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueGrey[700]),
                      onPressed: () => _showFormDialog(brand: brand),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteItem(brand.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
