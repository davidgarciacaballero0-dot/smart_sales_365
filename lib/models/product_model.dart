// lib/models/product_model.dart

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int? categoryId;
  final String? categoryName;
  final Map<String, dynamic>? categoryDetail;
  final Map<String, dynamic>? brand;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? hasReviewed; // NUEVO CAMPO

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.categoryDetail,
    this.brand,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.hasReviewed, // NUEVO PARÁMETRO
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _parseDouble(json['price']),
      stock: _parseInt(json['stock']),
      categoryId: json['category'] as int?,
      categoryName: json['category_name'] as String?,
      categoryDetail: json['category_detail'] as Map<String, dynamic>?,
      brand: json['brand'] as Map<String, dynamic>?,
      image: json['image'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      hasReviewed: json['has_reviewed'] as bool?, // NUEVO
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': categoryId,
      'category_name': categoryName,
      'category_detail': categoryDetail,
      'brand': brand,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'has_reviewed': hasReviewed, // NUEVO
    };
  }

  // Getters útiles
  String? get brandName => brand?['name'] as String?;
  String? get warrantyInfo => brand?['warranty_info'] as String?;
  int? get warrantyDurationMonths => brand?['warranty_duration_months'] as int?;
}
