// lib/screens/admin/charts/association_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// Un gráfico de burbujas (ScatterChart) que muestra las asociaciones de productos.
class AssociationChart extends StatelessWidget {
  /// Los datos de asociación, se esperan en una lista de mapas:
  /// [
  ///   { 'antecedents': ['Producto A'], 'consequents': ['Producto B'], 'confidence': 0.85 },
  ///   { 'antecedents': ['Producto C'], 'consequents': ['Producto D'], 'confidence': 0.72 }
  /// ]
  final List<dynamic> data;

  const AssociationChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No hay datos de asociación disponibles.'),
      );
    }

    // 1. Procesar los datos para el gráfico
    final scatterSpots = _prepareChartData();

    // 2. Encontrar los valores máximos para configurar los ejes
    final double maxConfidence = data
        .map<double>((item) => (item['confidence'] as num? ?? 0.0).toDouble())
        .reduce(max);

    return ScatterChart(
      ScatterChartData(
        // Eje X (horizontal) - Lo usaremos para el índice, pero lo ocultaremos
        minX: -1,
        maxX: data.length.toDouble(), // Tantas "columnas" como datos
        // Eje Y (vertical) - Representará la confianza
        minY: 0,
        maxY: (maxConfidence * 1.2).clamp(0.1, 1.0), // 20% más alto, máx 1.0
        // Configuración de las burbujas
        scatterSpots: scatterSpots,

        // Configuración visual
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25, // Líneas en 0.25, 0.50, 0.75...
        ),
        borderData: FlBorderData(show: false),

        // Tooltips (lo que se ve al tocar una burbuja)
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          tooltipSettings: ScatterTooltipSettings(
            tooltipBgColor: Colors.black.withOpacity(0.8),
            getTooltipItems: (ScatterSpot spot) {
              final item = data[spot.x.toInt()];
              final String antecedents = (item['antecedents'] as List).join(
                ', ',
              );
              final String consequents = (item['consequents'] as List).join(
                ', ',
              );
              final String confidence = (spot.radius / 10).toStringAsFixed(
                2,
              ); // Invertir el cálculo del radio

              return ScatterTooltipItem(
                'Si compran:\n',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '$antecedents\n\n',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const TextSpan(
                    text: 'También compran:\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '$consequents\n\n',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextSpan(
                    text: 'Confianza: $confidence',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                bottomMargin: 10,
                width: 200,
              );
            },
          ),
        ),

        // Títulos de los ejes
        titlesData: FlTitlesData(
          // Eje Y (Izquierda) - Muestra la Confianza
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 0.25,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value > maxConfidence.clamp(0.1, 1.0))
                  return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          // Ocultar el resto de los ejes
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }

  /// Prepara los datos de la lista para que fl_chart pueda entenderlos.
  List<ScatterSpot> _prepareChartData() {
    final List<ScatterSpot> spots = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      if (item['confidence'] is num) {
        final double confidence = (item['confidence'] as num).toDouble();

        spots.add(
          ScatterSpot(
            i.toDouble(), // Posición X (índice)
            confidence, // Posición Y (valor de confianza)
            // El radio (tamaño de la burbuja) también se basa en la confianza.
            // Multiplicamos por 10 para que sea visible (ej. 0.85 -> 8.5)
            radius: (confidence * 10).clamp(2, 20),

            color: colors[i % colors.length].withOpacity(0.7),
          ),
        );
      }
    }
    return spots;
  }
}
