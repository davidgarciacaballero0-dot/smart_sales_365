// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sales_365/services/auth_service.dart';
import 'package:smart_sales_365/models/user_model.dart'; // <-- CORRECCIÓN: Importar el modelo 'User'

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  String? _token;
  User? _user; // <-- CORRECCIÓN: De 'AuthUser' a 'User'
  bool _isLoading = true;

  String? get token => _token;
  User? get user => _user; // <-- CORRECCIÓN: De 'AuthUser' a 'User'
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _token = prefs.getString('token');
    final userData = prefs.getString('user');

    if (userData != null) {
      try {
        _user = User.fromJson(
          json.decode(userData),
        ); // <-- CORRECCIÓN: De 'AuthUser' a 'User'
      } catch (e) {
        // Si hay un error decodificando, simplemente borramos los datos viejos
        await prefs.remove('user');
        await prefs.remove('token');
        _token = null;
        _user = null;
      }
    }

    if (_token != null) {
      // Opcional: Podrías validar el token con el backend aquí
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final responseData = await _authService.login(email, password);
      _token = responseData['token'];
      _user = User.fromJson(
        responseData['user'],
      ); // <-- CORRECCIÓN: De 'AuthUser' a 'User'

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
      // Guardamos el usuario como un string JSON
      prefs.setString('user', json.encode(responseData['user']));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final responseData = await _authService.register(
        username,
        email,
        password,
      );
      _token = responseData['token'];
      _user = User.fromJson(
        responseData['user'],
      ); // <-- CORRECCIÓN: De 'AuthUser' a 'User'

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
      // Guardamos el usuario como un string JSON
      prefs.setString('user', json.encode(responseData['user']));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('user');
    notifyListeners();
  }
}
