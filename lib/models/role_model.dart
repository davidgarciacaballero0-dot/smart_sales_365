// lib/models/role_model.dart

class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  // Factory constructor para crear un Role desde un JSON
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'], name: json['name']);
  }
}
