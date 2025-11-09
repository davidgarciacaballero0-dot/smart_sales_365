// lib/models/user_model.dart

import 'package:smartsales365/models/role_model.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final Role role;
  final bool isActive; // Para saber si el usuario está activo

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
  });

  // Factory constructor para crear un User desde un JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      // El backend anida el objeto 'role' dentro del usuario
      role: Role.fromJson(json['role']),
      isActive: json['is_active'] ?? true,
    );
  }

  // Método de conveniencia para obtener el nombre completo
  String get fullName => '$firstName $lastName'.trim();
}
