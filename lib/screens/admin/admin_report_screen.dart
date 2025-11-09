// lib/screens/admin/admin_report_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/report_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  final _reportService = ReportService();
  final _promptController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage =
      'Escribe una solicitud para generar un reporte de ventas (ej: "ventas totales del último mes agrupadas por categoría").';

  Future<void> _generateReport() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa una solicitud.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Generando reporte...';
    });

    // CORRECCIÓN 1/1:
    // Cambiado de 'accessToken' a 'token' para que coincida con tu AuthProvider
    final String? token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: No autorizado. Inicia sesión de nuevo.';
      });
      return;
    }

    try {
      final prompt = _promptController.text;
      final pdfBytes = await _reportService.generateReport(
        token,
        prompt,
        token: '',
        prompt: '',
        format: '',
      );

      // Guardar el archivo
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      // Añade timestamp para nombre único
      final fileName =
          'reporte_ia_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$path/$fileName');
      await file.writeAsBytes(pdfBytes);

      setState(() {
        _isLoading = false;
        _statusMessage =
            '¡Reporte generado! Abriendo $fileName... \n\nÚltima solicitud: "$prompt"';
      });

      // Abrir el archivo
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('No se pudo abrir el archivo PDF: ${result.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error al generar el reporte: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes IA')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Solicitud de Reporte (IA)',
                border: OutlineInputBorder(),
                hintText: 'Ej: ventas totales por marca...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generar Reporte (PDF)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.startsWith('Error')
                            ? Colors.red
                            : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
