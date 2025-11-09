// lib/screens/admin/charts/sentiment_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Un gráfico de pastel que muestra el análisis de sentimiento.
class SentimentChart extends StatelessWidget {
  /// Los datos de sentimiento, se esperan en un formato como:
  /// { 'average_rating': 4.2, 'total_reviews': 100, 'sentiment_distribution': { 'positive': 70, 'neutral': 20, 'negative': 10 } }
  final Map<String, dynamic> data;

  const SentimentChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 1. Extraer y procesar los datos
    final Map<String, dynamic> sentiments = _getSentimentDistribution();
    final double totalReviews = (data['total_reviews'] is num)
        ? (data['total_reviews'] as num).toDouble()
        : 0.0;

    if (sentiments.isEmpty || totalReviews == 0.0) {
      return const Center(
        child: Text('No hay datos de sentimiento disponibles.'),
      );
    }

    // 2. Construir la lista de secciones del gráfico
    final List<PieChartSectionData> sections = _buildChartSections(
      sentiments,
      totalReviews,
    );

    // 3. Construir el gráfico
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 60, // Esto lo convierte en un gráfico de "dona"
            sectionsSpace: 2, // Espacio entre secciones
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Aquí podrías manejar los toques si quisieras
              },
            ),
          ),
        ),
        // Texto en el centro del gráfico
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              totalReviews.toInt().toString(),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text('Reseñas'),
          ],
        ),
      ],
    );
  }

  /// Extrae de forma segura la distribución de sentimientos del mapa de datos.
  Map<String, dynamic> _getSentimentDistribution() {
    if (data.containsKey('sentiment_distribution') &&
        data['sentiment_distribution'] is Map<String, dynamic>) {
      return data['sentiment_distribution'] as Map<String, dynamic>;
    }
    return {};
  }

  /// Construye las "rebanadas" del gráfico de pastel.
  List<PieChartSectionData> _buildChartSections(
    Map<String, dynamic> sentiments,
    double totalReviews,
  ) {
    final List<PieChartSectionData> list = [];

    // Función auxiliar para crear cada sección
    void createSection(String key, Color color) {
      if (sentiments.containsKey(key) && sentiments[key] is num) {
        final double value = (sentiments[key] as num).toDouble();
        final double percentage = (value / totalReviews) * 100;

        list.add(
          PieChartSectionData(
            value: value,
            title: '${percentage.toStringAsFixed(0)}%', // Mostrar porcentaje
            radius: 30,
            color: color,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
        );
      }
    }

    // Crear secciones para cada tipo de sentimiento
    // El orden aquí define el orden en el gráfico (ej. Verde primero)
    createSection('positive', Colors.green.shade600);
    createSection('neutral', Colors.grey.shade500);
    createSection('negative', Colors.red.shade600);

    // Manejar cualquier otro sentimiento inesperado con un color por defecto
    sentiments.forEach((key, value) {
      if (key != 'positive' && key != 'neutral' && key != 'negative') {
        createSection(key, Colors.blue.shade600);
      }
    });

    return list;
  }
}
