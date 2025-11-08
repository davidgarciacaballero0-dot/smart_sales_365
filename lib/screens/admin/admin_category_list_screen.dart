// lib/screens/admin/admin_category_list_screen.dart

// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/models/category_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/category_brand_service.dart';

class AdminCategoryListScreen extends StatefulWidget {
  const AdminCategoryListScreen({super.key});

  @override
  State<AdminCategoryListScreen> createState() =>
      _AdminCategoryListScreenState();
}

class _AdminCategoryListScreenState extends State<AdminCategoryListScreen> {
  final CategoryBrandService _service = CategoryBrandService();
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _future = _service.getCategories();
    });
  }

  Future<void> _showFormDialog({Category? category}) async {
    final _nameController = TextEditingController(text: category?.name);
    final _descriptionController = TextEditingController(
      text: category?.description,
    );
    final _formKey = GlobalKey<FormState>();

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            category == null ? 'Crear Categoría' : 'Editar Categoría',
          ),
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
        if (category == null) {
          await _service.createCategory(token, result);
        } else {
          await _service.updateCategory(token, category.id, result);
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
        await _service.deleteCategory(token, id);
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
        title: const Text('Gestionar Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
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
              final category = items[index];
              return ListTile(
                title: Text(category.name),
                subtitle: Text(category.description ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueGrey[700]),
                      onPressed: () => _showFormDialog(category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteItem(category.id),
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
