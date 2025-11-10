// lib/models/user_model.dart

import 'package:smartsales365/models/role_model.dart';

// Modelo para el perfil de usuario (obtenido de /api/users/me/)
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final Role role;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: Role.fromJson(json['role']),
    );
  }

  // Método para serializar a JSON (para guardar en storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.toJson(),
    };
  }

  // Getter para nombre completo
  String get fullName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return username;
  }
}

// Modelo para la lista de usuarios (obtenido de /api/users/)
// Es un modelo simplificado
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final Role role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      // El backend (UserListSerializer) envía el 'role' anidado
      role: Role.fromJson(json['role']),
    );
  }

  // Getter para nombre completo
  String get fullName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return username;
  }
}
