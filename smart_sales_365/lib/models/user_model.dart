// lib/models/user_model.dart
class User {
  final int id;
  final String username;
  final String email;
  final String? roleName; // <-- CORRECCIÓN: Añadido para guardar el rol

  User({
    required this.id,
    required this.username,
    required this.email,
    this.roleName, // <-- CORRECCIÓN: Añadido al constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      roleName:
          json['role_name'], // <-- CORRECCIÓN: Leemos 'role_name' del JSON
    );
  }
}
