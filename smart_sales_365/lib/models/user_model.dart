// lib/models/user_model.dart
import 'package:flutter/foundation.dart';

// Esta clase representa al usuario autenticado.
// Sus datos se obtienen decodificando el token JWT.
@immutable
class AuthUser {
  final String userId;
  final String username;
  final String email;
  final int? roleId;
  final String? roleName;
  final int exp; // Timestamp de expiración del token

  const AuthUser({
    required this.userId,
    required this.username,
    required this.email,
    this.roleId,
    this.roleName,
    required this.exp,
  });

  // Constructor 'factory' para crear una instancia de AuthUser
  // desde el mapa (JSON) que obtenemos al decodificar el JWT.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // Basado en backend.github: users/serializers.py (MyTokenObtainPairSerializer)
    return AuthUser(
      // simple-jwt usa 'user_id'
      userId: json['user_id']?.toString() ?? '',
      username: json['username'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      roleId: json['role_id'] as int?,
      roleName: json['role_name'] as String?,
      // 'exp' es el timestamp de expiración estándar de JWT
      exp: json['exp'] ?? 0,
    );
  }

  // Método para convertir nuestra clase de nuevo a un JSON.
  // Útil si queremos guardar todo el objeto de usuario en SharedPreferences.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'role_id': roleId,
      'role_name': roleName,
      'exp': exp,
    };
  }

  // Un 'getter' simple para saber si el usuario es Administrador.
  // Basado en el 'role_name' que define el backend.
  bool get isAdmin => roleName?.toUpperCase() == 'ADMINISTRADOR';
  // Un 'getter' para saber si es Cliente.
  bool get isClient => roleName?.toUpperCase() == 'CLIENTE';
}
