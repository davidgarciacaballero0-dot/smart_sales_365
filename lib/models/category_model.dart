// lib/models/category_model.dart

class Category {
  final int id;
  final String name;
  final String? description;

  // Constructor
  Category({required this.id, required this.name, this.description});

  // Constructor 'factory' para crear una instancia de Category desde un JSON.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}
