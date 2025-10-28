// lib/models/product_model.dart
import 'package:flutter/foundation.dart';

@immutable
class Product {
  final int id;
  final String name;
  final String description;
  final double price; // Django usa DecimalField, Dart usa double
  final int stock;
  final int categoryId; // El ID de la categoría
  final String categoryName; // El nombre de la categoría (del serializer)
  final int brandId; // El ID de la marca
  final String brandName; // El nombre de la marca (del serializer)
  final String? image; // URL de la imagen (de Cloudinary, puede ser null)

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    required this.brandId,
    required this.brandName,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      // Convertimos el precio (String en JSON) a double
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      stock: json['stock'] as int,
      // El serializer devuelve 'category' (ID) y 'category_name' (nombre)
      categoryId: json['category'] as int,
      categoryName: json['category_name'] as String? ?? 'Sin Categoría',
      // El serializer devuelve 'brand' (ID) y 'brand_name' (nombre)
      brandId: json['brand'] as int,
      brandName: json['brand_name'] as String? ?? 'Sin Marca',
      // La imagen puede ser null
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
      'brand': brandId,
      'brand_name': brandName,
      'image': image,
    };
  }
}
