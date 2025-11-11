// lib/models/product_model.dart

/// Modelo Product que refleja EXACTAMENTE la estructura del backend
/// Basado en ProductSerializer de Django REST Framework
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;

  // Category fields
  final int? categoryId;
  final String? categoryName;
  final Map<String, dynamic>? categoryDetail; // CategorySerializer completo

  // Brand fields (BrandSerializer completo)
  final int? brandId;
  final Map<String, dynamic>? brand;

  // Image from Cloudinary
  final String? image;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.categoryDetail,
    this.brandId,
    this.brand,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _parseDouble(json['price']),
      stock: _parseInt(json['stock']),
      // Category fields
      categoryId: json['category'] as int?,
      categoryName: json['category_name'] as String?,
      categoryDetail: json['category_detail'] as Map<String, dynamic>?,
      // Brand fields
      brandId: json['brand_id'] as int?,
      brand: json['brand'] as Map<String, dynamic>?,
      // Image
      image: json['image'] as String?,
      // Timestamps
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
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
      'brand_id': brandId,
      'brand': brand,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Getters útiles para acceder a datos anidados
  String? get brandName => brand?['name'] as String?;
  String? get brandDescription => brand?['description'] as String?;
  String? get warrantyInfo => brand?['warranty_info'] as String?;
  int? get warrantyDurationMonths => brand?['warranty_duration_months'] as int?;

  // Category getters
  String? get categoryDescription => categoryDetail?['description'] as String?;
}
