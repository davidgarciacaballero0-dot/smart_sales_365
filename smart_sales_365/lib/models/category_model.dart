// lib/models/category_model.dart
import 'package:flutter/foundation.dart';

@immutable
class Category {
  final int id;
  final String name;
  final String? description; // Django lo tiene como 'blank=True, null=True'

  const Category({required this.id, required this.name, this.description});

  // Constructor factory para crear desde JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  // Método para convertir a JSON (útil para debug o guardar localmente)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}
