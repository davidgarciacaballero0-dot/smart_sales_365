// lib/models/product_model.dart
class Product {
  final int id;
  final String name;
  final String? description; // Ya era nullable
  final double price;
  final int stock;
  final String categoryName;
  final String brandName;
  final String? image; // <-- MODIFICACIÓN: De String a String?

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryName,
    required this.brandName,
    this.image, // <-- MODIFICACIÓN
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      categoryName: json['category_name'],
      brandName: json['brand_name'],
      image: json['image'], // <-- MODIFICACIÓN
    );
  }
}
