// lib/models/product_model.dart

import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? image;
  final Category categoryDetail;
  final Brand? brand;
  final double averageRating;
  final int reviewCount;
  // CORRECCIÓN 1/3: Campo añadido
  final bool hasReviewed;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.image,
    required this.categoryDetail,
    this.brand,
    required this.averageRating,
    required this.reviewCount,
    // CORRECCIÓN 2/3: Añadido al constructor
    required this.hasReviewed,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      image: json['image'],
      categoryDetail: Category.fromJson(json['category_detail']),
      brand: json['brand'] != null ? Brand.fromJson(json['brand']) : null,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      // CORRECCIÓN 3/3: Añadido al 'fromJson'
      // El backend lo envía como 'has_reviewed' (en getProductById)
      // Usamos '?? false' para la lista del catálogo (que no lo envía)
      hasReviewed: json['has_reviewed'] ?? false,
    );
  }

  // Getter para mostrar el precio formateado
  String get formattedPrice {
    return 'Bs. ${price.toStringAsFixed(2)}';
  }

  // Getter para la información de garantía
  String? get warrantyInfo {
    final months = brand?.warrantyDurationMonths;
    if (months != null && months > 0) {
      return '$months meses de garantía';
    }
    return null;
  }
}
