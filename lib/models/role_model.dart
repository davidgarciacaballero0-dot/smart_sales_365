// lib/models/role_model.dart

class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'], name: json['name']);
  }

  // Método para serializar a JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
