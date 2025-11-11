// lib/models/login_response_model.dart

/// Modelo para la respuesta de login según MyTokenObtainPairSerializer del backend
/// Backend retorna: {access, refresh, user: {id, username, email, role}}
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserData user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'user': user.toJson(),
    };
  }
}

/// Modelo para los datos del usuario incluidos en la respuesta de login
/// Según MyTokenObtainPairSerializer: {id, username, email, role}
class UserData {
  final int id;
  final String username;
  final String email;
  final String? role; // Puede ser null si el usuario no tiene rol asignado

  UserData({
    required this.id,
    required this.username,
    required this.email,
    this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'email': email, 'role': role};
  }

  /// Verifica si el usuario es administrador
  bool get isAdmin => role == 'ADMINISTRADOR';

  /// Verifica si el usuario es cliente
  bool get isClient => role == 'CLIENTE';
}
