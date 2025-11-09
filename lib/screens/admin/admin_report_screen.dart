// lib/screens/admin/admin_report_screen.dart

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsales365/providers/auth_provider.dart';
import 'package:smartsales365/services/report_service.dart';
import 'package:open_filex/open_filex.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _reportService = ReportService();

  String _selectedFormat = 'pdf'; // Valor por defecto
  bool _isGenerating = false;

  Future<void> _generateReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
    });

    final String? token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de autenticación'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isGenerating = false;
      });
      return;
    }

    try {
      // 1. CORRECCIÓN: Llama al servicio usando parámetros nombrados.
      final String filePath = await _reportService.generateReport(
        token: token,
        prompt: _promptController.text,
        format: _selectedFormat,
      );

      // 2. CORRECCIÓN: 'filePath' ya es un String (la ruta).
      //    Ya no necesitamos escribir el archivo, el servicio lo hizo.
      //    Simplemente lo abrimos.
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('No se pudo abrir el archivo: ${result.message}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generador de Reportes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Generar Reporte Dinámico',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Escribe una consulta en lenguaje natural para generar un reporte. El sistema la interpretará y generará un archivo PDF o Excel.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // --- Campo de Texto (Prompt) ---
              TextFormField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Escribe tu consulta...',
                  hintText: 'Ej: "Ventas totales del último mes por categoría"',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // --- Selector de Formato ---
              const Text(
                'Formato de Salida:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('PDF (.pdf)'),
                value: 'pdf',
                groupValue: _selectedFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Excel (.xlsx)'),
                value: 'excel',
                groupValue: _selectedFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // --- Botón de Generar ---
              ElevatedButton.icon(
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.description_outlined),
                label: Text(_isGenerating ? 'Generando...' : 'Generar Reporte'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: _isGenerating ? null : _generateReport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
