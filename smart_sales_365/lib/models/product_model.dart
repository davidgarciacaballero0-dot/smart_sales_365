// lib/models/product_model.dart
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String categoryName;
  final String brandName;
  final String? image;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryName,
    required this.brandName,
    this.image,
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
      image: json['image'],
    );
  }

  // --- MÉTODO AÑADIDO ---
  // Requerido por cart_item_model.dart
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category_name': categoryName,
      'brand_name': brandName,
      'image': image,
    };
  }
  // --- FIN DE LA MODIFICACIÓN ---
}
