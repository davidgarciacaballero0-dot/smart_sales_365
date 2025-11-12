// lib/utils/error_handler.dart

import 'package:flutter/material.dart';

/// Utilidad para manejar errores y mostrar mensajes al usuario
class ErrorHandler {
  /// Extrae un mensaje legible de un error
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Error desconocido';

    final errorString = error.toString();

    // Si es una Exception con mensaje
    if (errorString.startsWith('Exception: ')) {
      return errorString.replaceFirst('Exception: ', '');
    }

    // Si es muy corto o truncado (como "G"), dar mensaje genérico
    if (errorString.length < 3) {
      return 'Error al procesar la solicitud';
    }

    return errorString;
  }

  /// Muestra un SnackBar de error con el mensaje apropiado
  static void showError(BuildContext context, dynamic error, {String? prefix}) {
    final message = getErrorMessage(error);
    final fullMessage = prefix != null ? '$prefix: $message' : message;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fullMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Muestra un SnackBar de éxito
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Muestra un SnackBar de información
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Maneja errores comunes de HTTP
  static String handleHttpError(int statusCode, String? body) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida';
      case 401:
        return 'No autorizado. Por favor, inicia sesión nuevamente';
      case 403:
        return 'Acceso denegado';
      case 404:
        return 'Recurso no encontrado';
      case 500:
        return 'Error del servidor. Intenta más tarde';
      case 502:
        return 'Servicio no disponible temporalmente';
      case 503:
        return 'Servicio en mantenimiento';
      default:
        return 'Error de conexión (código $statusCode)';
    }
  }
}
