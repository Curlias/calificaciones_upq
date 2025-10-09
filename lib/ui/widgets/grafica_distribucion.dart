import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/alumno.dart';

class GraficaDistribucion extends StatelessWidget {
  final List<Alumno> alumnos;

  const GraficaDistribucion({
    super.key,
    required this.alumnos,
  });

  @override
  Widget build(BuildContext context) {
    final distribucionData = _calcularDistribucion();
    
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(
        title: AxisTitle(text: 'Rango de Calificaciones'),
      ),
      primaryYAxis: const NumericAxis(
        title: AxisTitle(text: 'Número de Alumnos'),
      ),
      title: const ChartTitle(text: 'Distribución de Calificaciones Finales'),
      legend: const Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<DistribucionData, String>>[
        ColumnSeries<DistribucionData, String>(
          dataSource: distribucionData,
          xValueMapper: (DistribucionData data, _) => data.rango,
          yValueMapper: (DistribucionData data, _) => data.cantidad,
          pointColorMapper: (DistribucionData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  List<DistribucionData> _calcularDistribucion() {
    // Definir rangos de calificaciones
    final rangos = [
      ('0.0-2.9', 0.0, 2.9, Colors.red),
      ('3.0-4.9', 3.0, 4.9, Colors.deepOrange),
      ('5.0-6.9', 5.0, 6.9, Colors.orange),
      ('7.0-7.9', 7.0, 7.9, Colors.yellow[700]!),
      ('8.0-8.9', 8.0, 8.9, Colors.lightGreen),
      ('9.0-10.0', 9.0, 10.0, Colors.green),
      ('Sin Calificar', -1.0, -1.0, Colors.grey),
    ];

    final contadores = <String, int>{};
    final colores = <String, Color>{};

    // Inicializar contadores
    for (final rango in rangos) {
      contadores[rango.$1] = 0;
      colores[rango.$1] = rango.$4;
    }

    // Contar alumnos por rango
    for (final alumno in alumnos) {
      final calificacion = alumno.calcularCalificacionFinalCalculada();
      
      if (calificacion == null) {
        contadores['Sin Calificar'] = contadores['Sin Calificar']! + 1;
      } else {
        bool asignado = false;
        for (final rango in rangos) {
          if (rango.$1 != 'Sin Calificar' && 
              calificacion >= rango.$2 && 
              calificacion <= rango.$3) {
            contadores[rango.$1] = contadores[rango.$1]! + 1;
            asignado = true;
            break;
          }
        }
        if (!asignado && calificacion >= 0) {
          // Fallback para valores fuera de rango
          contadores['9.0-10.0'] = contadores['9.0-10.0']! + 1;
        }
      }
    }

    // Convertir a lista para la gráfica
    return contadores.entries
        .where((entry) => entry.value > 0) // Solo mostrar rangos con datos
        .map((entry) => DistribucionData(
              rango: entry.key,
              cantidad: entry.value,
              color: colores[entry.key]!,
            ))
        .toList();
  }
}

class DistribucionData {
  final String rango;
  final int cantidad;
  final Color color;

  DistribucionData({
    required this.rango,
    required this.cantidad,
    required this.color,
  });
}