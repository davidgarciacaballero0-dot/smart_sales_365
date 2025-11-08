// lib/services/analytics_service.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsService {
  static const String _baseUrl =
      'httpsS://smartsales-backend-891739940726.us-central1.run.app/api';

  /// Obtiene las predicciones de ventas
  /// Requiere el token de un administrador.
  Future<Map<String, dynamic>> getSalesPredictions(String token) async {
    // Llama a /api/analytics/sales-predictions/
    final Uri url = Uri.parse('$_baseUrl/analytics/sales-predictions/');
    print('Llamando a la API: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Devuelve el JSON de respuesta, ej: {'predictions': [...]}
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar predicciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // (Aquí añadiremos más métodos como getSentimentAnalysis, etc.)
}
