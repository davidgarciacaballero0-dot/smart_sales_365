// lib/screens/admin/charts/prediction_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Un gráfico de barras que muestra las predicciones de ventas.
class PredictionChart extends StatelessWidget {
  /// Los datos de predicción, se esperan en un formato como:
  /// { 'predictions': { '2023-10-27': 150.5, '2023-10-28': 180.0, ... } }
  final Map<String, dynamic> data;

  const PredictionChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 1. Extraer y procesar los datos
    final List<BarChartGroupData> barGroups = _prepareChartData();

    if (barGroups.isEmpty) {
      return const Center(
        child: Text('No hay datos de predicción disponibles.'),
      );
    }

    // 2. Construir el gráfico
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = (data['predictions'] as Map<String, dynamic>).keys
                  .elementAt(groupIndex);
              final formattedDate = DateFormat(
                'MMM d',
              ).format(DateTime.parse(date));
              final value = rod.toY.toStringAsFixed(2);
              return BarTooltipItem(
                '$formattedDate\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '\$ $value',
                    style: const TextStyle(color: Colors.yellow),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          // Títulos del eje X (inferior) - Las Fechas
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (double value, TitleMeta meta) {
                // value es el índice (0, 1, 2...)
                final index = value.toInt();
                if (data['predictions'] == null) return const SizedBox.shrink();

                final predictions =
                    (data['predictions'] as Map<String, dynamic>);
                if (index >= predictions.length) return const SizedBox.shrink();

                final dateString = predictions.keys.elementAt(index);
                final date = DateTime.parse(dateString);
                // Formatear la fecha como "Oct 27"
                final String text = DateFormat('MMM d').format(date);

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(text, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          // Ocultar títulos de la izquierda, derecha y arriba
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false), // Sin bordes
        gridData: const FlGridData(show: false), // Sin cuadrícula
        barGroups: barGroups,
      ),
    );
  }

  /// Prepara los datos del mapa para que fl_chart pueda entenderlos.
  List<BarChartGroupData> _prepareChartData() {
    final List<BarChartGroupData> barGroups = [];

    // Validar que los datos existan y tengan el formato esperado
    if (data.containsKey('predictions') &&
        data['predictions'] is Map<String, dynamic>) {
      final predictions = (data['predictions'] as Map<String, dynamic>);
      int index = 0;

      predictions.forEach((date, value) {
        // Asegurarnos de que el valor sea numérico
        final double yValue = (value is num) ? value.toDouble() : 0.0;

        barGroups.add(
          BarChartGroupData(
            x: index, // El índice de la barra
            barRods: [
              BarChartRodData(
                toY: yValue, // El valor (altura) de la barra
                color: Colors.teal,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
        index++;
      });
    }

    return barGroups;
  }
}
