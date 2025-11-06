// lib/models/product_model.dart

// Importamos los otros modelos que este archivo necesita
import 'package:smartsales365/models/brand_model.dart';
import 'package:smartsales365/models/category_model.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double price; // Usamos double para el precio
  final int stock;
  final Category categoryDetail; // Objeto anidado de Categoría
  final Brand? brand; // Objeto anidado de Marca (puede ser nulo)
  final String? image; // URL de la imagen de Cloudinary

  // Constructor
  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.categoryDetail,
    this.brand,
    this.image,
  });

  // Constructor 'factory' para crear un Producto desde JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],

      // El precio en Django es un Decimal, que JSON convierte a String.
      // Debemos convertir ese String a un double en Dart.
      price: double.parse(json['price']),

      stock: json['stock'],

      // Tu serializador usa 'category_detail' para el objeto anidado
      // Llamamos a Category.fromJson para construir el objeto Category.
      categoryDetail: Category.fromJson(json['category_detail']),

      // Tu serializador usa 'brand' para el objeto anidado
      // Verificamos si no es nulo antes de intentar 'traducirlo'
      brand: json['brand'] != null ? Brand.fromJson(json['brand']) : null,

      // 'image' es un CloudinaryField, que usualmente devuelve una URL (String)
      // En tu serializador se llama 'image'
      image: json['image'],
    );
  }
}
