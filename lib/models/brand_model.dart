// lib/models/brand_model.dart

class Brand {
  final int id;
  final String name;
  final String? description;
  final String? warrantyInfo;
  final int? warrantyDurationMonths;

  // Constructor
  Brand({
    required this.id,
    required this.name,
    this.description,
    this.warrantyInfo,
    this.warrantyDurationMonths,
  });

  // Constructor 'factory' para crear una instancia de Brand desde un JSON.
  // Esto es lo que 'traduce' la respuesta de tu API a un objeto Dart.
  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      warrantyInfo: json['warranty_info'],
      // En el serializador, 'warranty_duration_months' es el nombre del campo
      warrantyDurationMonths: json['warranty_duration_months'],
    );
  }
}
