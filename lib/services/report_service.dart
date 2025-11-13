// lib/services/report_service.dart

// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ReportService {
  static const String _baseUrl =
      'https://smartsales-backend-891739940726.us-central1.run.app/api';

  /// Genera un reporte dinámico y devuelve la RUTA del archivo guardado.
  Future<String> generateReport({
    required String token,
    required String prompt,
    required String format, // 'pdf' o 'excel'
  }) async {
    // CORRECCIÓN: Endpoint correcto del backend es /reports/dynamic-report/
    final Uri url = Uri.parse('$_baseUrl/reports/dynamic-report/');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 GENERANDO REPORTE DINÁMICO');
    print('🔗 URL: $url');
    print('📝 Prompt: $prompt');
    print('📄 Formato: $format');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final body = jsonEncode({'prompt': prompt, 'format': format});

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 1. Obtener los bytes del archivo desde la respuesta
        final bytes = response.bodyBytes;

        // 2. Obtener el directorio de archivos temporales del dispositivo
        final dir = await getTemporaryDirectory();

        // 3. Crear una ruta de archivo única
        final String fileExtension = format == 'pdf' ? 'pdf' : 'xlsx';
        final String filePath =
            '${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        // 4. Escribir los bytes en el archivo
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // 5. Devolver la ruta donde se guardó el archivo
        print('✅ Archivo guardado en: $filePath');
        return filePath;
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('📦 Response Body: ${response.body}');

        // Verificar si el endpoint existe
        if (response.statusCode == 404) {
          throw Exception(
            'El endpoint de reportes no fue encontrado.\n'
            'Verifica que /api/reports/dynamic-report/ esté implementado.\n'
            'Status: 404 - Endpoint no encontrado',
          );
        }

        throw Exception(
          'Error al generar el reporte: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      print('❌ Excepción capturada: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}
