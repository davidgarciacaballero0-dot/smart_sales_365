// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

// Clase base para todos los servicios
class ApiService {
  final String baseUrl =
      'https://smartsales-backend-891739940726.us-central1.run.app/api';

  // Función de ayuda para manejar respuestas de API (opcional pero recomendado)
  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Éxito (200, 201, 204)
      if (response.body.isEmpty) {
        return null; // Para respuestas 204 No Content
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // Error (4xx, 5xx)
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      String errorMessage = 'Error desconocido';

      if (errorData is Map) {
        try {
          // Intenta acceder al error de Django (ej: {'username': ['ya existe']})
          errorMessage = errorData.values.first[0].toString();
        } catch (e) {
          // Si el formato es diferente (ej: {'detail': '...'})
          errorMessage = errorData['detail'] ?? errorData.toString();
        }
      }
      throw Exception(errorMessage);
    }
  }
}
