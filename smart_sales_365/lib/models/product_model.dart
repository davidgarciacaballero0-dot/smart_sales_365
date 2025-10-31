// lib/models/product_model.dart
import 'package:flutter/foundation.dart';
import 'package:smart_sales_365/models/brand_model.dart'; // Asegúrate de que este archivo existe

@immutable
class Product {
  final int id;
  final String name;
  final String description;
  final double price; // Django usa DecimalField, Dart usa double
  final int stock;
  final int categoryId; // El ID de la categoría
  final String categoryName; // El nombre de la categoría (del serializer)

  // --- CORRECCIÓN ---
  // 'brand' ahora es un objeto 'Brand' completo (o null)
  final Brand? brand;
  // --------------------

  final String? image; // URL de la imagen (de Cloudinary, puede ser null)

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    this.brand, // <-- Campo actualizado
    this.image,
  });

  // Un 'getter' para acceder fácilmente al nombre de la marca
  // Esto asegura que el resto de la app (como ProductDetailScreen)
  // pueda seguir usando 'product.brandName' sin romperse.
  String get brandName => brand?.name ?? 'Sin Marca';

  factory Product.fromJson(Map<String, dynamic> json) {
    // --- CORRECCIÓN ---
    // Decodificamos el objeto 'brand' anidado si no es null
    final brandJson = json['brand'] as Map<String, dynamic>?;
    // --------------------

    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      // Convertimos el precio (String en JSON) a double
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      stock: json['stock'] as int,
      // El serializer devuelve 'category' (ID) y 'category_name'
      categoryId: json['category'] as int,
      categoryName: json['category_name'] as String? ?? 'Sin Categoría',

      // --- CORRECCIÓN ---
      // Creamos un objeto Brand a partir del JSON anidado
      brand: brandJson != null ? Brand.fromJson(brandJson) : null,

      // --------------------
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price.toString(), // Convertir a String para ser consistente
      'stock': stock,
      'category': categoryId,
      'category_name': categoryName,
      'brand': brand?.toJson(), // <-- Campo actualizado
      'image': image,
    };
  }
}
