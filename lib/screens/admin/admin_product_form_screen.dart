// lib/screens/admin/admin_product_form_screen.dart

// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures, deprecated_member_use, depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';
import 'package:smartsales365/models/product_model.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/category_brand_service.dart';
import 'package:smartsales365/services/product_service.dart';

class AdminProductFormScreen extends StatefulWidget {
  // Si 'product' no es nulo, estamos en modo "Editar".
  // Si es nulo, estamos en modo "Crear".
  final Product? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryBrandService = CategoryBrandService();
  final _productService = ProductService();

  // Controladores para los campos del formulario
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  // Variables para los menús desplegables
  int? _selectedCategoryId;
  int? _selectedBrandId;

  // Variables para imagen
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Estado de carga
  late Future<Map<String, dynamic>> _dropdownDataFuture;
  bool _isSaving = false;

  // Modo "Editar"
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Inicializa los controladores
    _nameController = TextEditingController(text: widget.product?.name);
    _descriptionController = TextEditingController(
      text: widget.product?.description,
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString(),
    );

    // Asigna los valores iniciales para los desplegables si estamos editando
    _selectedCategoryId =
        widget.product?.categoryDetail?['id'] as int?; // Línea 63
    _selectedBrandId = widget.product?.brand?['id'] as int?;
    // Carga los datos para los menús desplegables
    _dropdownDataFuture = _loadDropdownData();
  }

  /// Carga categorías y marcas al mismo tiempo
  Future<Map<String, dynamic>> _loadDropdownData() async {
    try {
      final categories = await _categoryBrandService.getCategories();
      final brands = await _categoryBrandService.getBrands();
      return {'categories': categories, 'brands': brands};
    } catch (e) {
      rethrow;
    }
  }

  /// Seleccionar imagen desde la galería
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Seleccionar imagen desde la cámara
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostrar diálogo para elegir fuente de imagen
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Envía el formulario
  Future<void> _submitForm() async {
    // 1. Valida el formulario
    if (!_formKey.currentState!.validate()) return;

    // 2. Valida los desplegables
    if (_selectedCategoryId == null || _selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una categoría y una marca.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // CORRECCIÓN 1/1:
    // Cambiado de 'accessToken' a 'token' para que coincida con tu AuthProvider
    final String? token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de autenticación'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    // 3. Prepara los datos para enviar
    final productData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'category_id': _selectedCategoryId!,
      'brand_id': _selectedBrandId!,
    };

    try {
      // 4. Llama al servicio (Crear o Actualizar)
      if (_isEditing) {
        // Si hay imagen seleccionada, usar método con imagen
        if (_selectedImage != null) {
          await _productService.updateProductWithImage(
            token,
            widget.product!.id,
            productData,
            _selectedImage!,
          );
        } else {
          // Sin imagen, usar método normal
          await _productService.updateProduct(
            token,
            widget.product!.id,
            productData,
          );
        }
      } else {
        // Crear producto nuevo
        if (_selectedImage != null) {
          await _productService.createProductWithImage(
            token,
            productData,
            _selectedImage!,
          );
        } else {
          await _productService.createProduct(token, productData);
        }
      }

      // 5. Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Producto ${_isEditing ? "actualizado" : "creado"} exitosamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Regresa a la lista (y le envía 'true' para que se refresque)
      Navigator.of(context).pop(true);
    } catch (e) {
      // 6. Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    // Limpia los controladores
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Crear Producto'),
      ),
      // FutureBuilder para cargar los desplegables
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dropdownDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar datos del formulario: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No se pudieron cargar los datos.'),
            );
          }

          // Listas para los desplegables
          final List<Category> categories = snapshot.data!['categories'];
          final List<Brand> brands = snapshot.data!['brands'];

          // Construye el formulario
          return _buildForm(categories, brands);
        },
      ),
    );
  }

  /// Widget que construye el formulario principal
  Widget _buildForm(List<Category> categories, List<Brand> brands) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Nombre ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // --- Imagen del Producto ---
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Imagen del Producto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Preview de la imagen
                  if (_selectedImage != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Eliminar imagen',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                  else if (_isEditing && widget.product?.image != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product!.image!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Imagen actual del producto',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )
                  else
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Sin imagen',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Botón para seleccionar imagen
                  ElevatedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(
                      _selectedImage != null ||
                              (_isEditing && widget.product?.image != null)
                          ? 'Cambiar imagen'
                          : 'Seleccionar imagen',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Descripción ---
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // --- Precio ---
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio (Bs.)',
                border: OutlineInputBorder(),
                prefixText: 'Bs. ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo requerido';
                if (double.tryParse(value) == null)
                  return 'Ingrese un número válido';
                if (double.parse(value) <= 0)
                  return 'El precio debe ser positivo';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // --- Stock ---
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock (Unidades)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Campo requerido';
                if (int.tryParse(value) == null)
                  return 'Ingrese un número entero';
                if (int.parse(value) < 0)
                  return 'El stock no puede ser negativo';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // --- Desplegable de Categoría ---
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              items: categories.map((Category category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null) ? 'Seleccione una categoría' : null,
            ),
            const SizedBox(height: 16),

            // --- Desplegable de Marca ---
            DropdownButtonFormField<int>(
              value: _selectedBrandId,
              items: brands.map((Brand brand) {
                return DropdownMenuItem<int>(
                  value: brand.id,
                  child: Text(brand.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBrandId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null) ? 'Seleccione una marca' : null,
            ),
            const SizedBox(height: 24),

            // --- Botón de Guardar ---
            ElevatedButton(
              onPressed: _isSaving ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEditing ? 'Guardar Cambios' : 'Crear Producto',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
