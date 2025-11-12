// lib/services/authenticated_http_client.dart

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:smartsales365/providers/auth_provider.dart';

/// Cliente HTTP que maneja automáticamente el refresh de tokens
///
/// Características:
/// - Intercepta errores 401 (token expirado)
/// - Intenta refresh del access token automáticamente (una sola vez)
/// - Reintenta la petición original con el nuevo token
/// - Evita múltiples refreshes simultáneos
/// - Si el refresh falla, fuerza logout
class AuthenticatedHttpClient {
  final AuthProvider authProvider;

  // Control de refresh en progreso para evitar múltiples refreshes simultáneos
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  AuthenticatedHttpClient({required this.authProvider});

  /// Ejecuta una petición HTTP con retry automático en caso de 401
  ///
  /// [request] es una función que recibe el token y retorna un `Future<http.Response>`
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final response = await client.executeWithAuth((token) {
  ///   return http.get(
  ///     Uri.parse('$baseUrl/products/'),
  ///     headers: {'Authorization': 'Bearer $token'},
  ///   );
  /// });
  /// ```
  Future<http.Response> executeWithAuth(
    Future<http.Response> Function(String token) request,
  ) async {
    final String? token = authProvider.accessToken;

    if (token == null) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      // Intento 1: Ejecutar request con token actual
      final response = await request(token);

      // Si no es 401, retornar respuesta tal cual
      if (response.statusCode != 401) {
        return response;
      }

      // Si es 401, intentar refresh
      print('🔄 Token expirado (401), intentando refresh...');

      // Esperar si ya hay un refresh en progreso
      final newToken = await _getRefreshedToken();

      if (newToken == null) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente');
      }

      // Intento 2: Reintentar request con nuevo token
      print('🔁 Reintentando request con nuevo token...');
      final retryResponse = await request(newToken);

      return retryResponse;
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('La petición tardó demasiado. Verifica tu conexión');
      }
      rethrow;
    }
  }

  /// Obtiene un token refrescado, evitando múltiples refreshes simultáneos
  Future<String?> _getRefreshedToken() async {
    // Si ya hay un refresh en progreso, esperar a que termine
    if (_isRefreshing) {
      print('⏳ Esperando refresh en progreso...');
      final completer = Completer<String?>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    // Iniciar refresh
    _isRefreshing = true;

    try {
      final success = await authProvider.refreshAccessToken();

      if (success) {
        final newToken = authProvider.accessToken;
        print('✅ Token refrescado exitosamente');

        // Notificar a todos los que estaban esperando
        for (var completer in _refreshQueue) {
          completer.complete(newToken);
        }
        _refreshQueue.clear();

        return newToken;
      } else {
        print('❌ Falló el refresh del token');

        // Notificar fallo a todos los que esperaban
        for (var completer in _refreshQueue) {
          completer.complete(null);
        }
        _refreshQueue.clear();

        return null;
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Ejecuta GET con retry automático
  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return executeWithAuth((token) {
      final allHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      };

      final request = http.get(uri, headers: allHeaders);

      if (timeout != null) {
        return request.timeout(timeout);
      }
      return request;
    });
  }

  /// Ejecuta POST con retry automático
  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return executeWithAuth((token) {
      final allHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      };

      final request = http.post(uri, headers: allHeaders, body: body);

      if (timeout != null) {
        return request.timeout(timeout);
      }
      return request;
    });
  }

  /// Ejecuta PUT con retry automático
  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return executeWithAuth((token) {
      final allHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      };

      final request = http.put(uri, headers: allHeaders, body: body);

      if (timeout != null) {
        return request.timeout(timeout);
      }
      return request;
    });
  }

  /// Ejecuta DELETE con retry automático
  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return executeWithAuth((token) {
      final allHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      };

      final request = http.delete(uri, headers: allHeaders, body: body);

      if (timeout != null) {
        return request.timeout(timeout);
      }
      return request;
    });
  }
}
