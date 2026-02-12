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
        labelRotation: -45,
        labelStyle: TextStyle(fontSize: 10),
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
    // Agrupar alumnos por matrícula y calcular su promedio general
    final Map<String, List<double>> calificacionesPorMatricula = {};
    
    for (final alumno in alumnos) {
      final cal = alumno.calcularCalificacionFinalCalculada();
      if (cal != null) {
        if (!calificacionesPorMatricula.containsKey(alumno.matricula)) {
          calificacionesPorMatricula[alumno.matricula] = [];
        }
        calificacionesPorMatricula[alumno.matricula]!.add(cal);
      }
    }

    // Alumnos sin ninguna calificación
    final Set<String> matriculasConCalificacion = calificacionesPorMatricula.keys.toSet();
    final Set<String> todasLasMatriculas = alumnos.map((a) => a.matricula).toSet();
    final int alumnosSinCalificar = todasLasMatriculas.difference(matriculasConCalificacion).length;

    // Definir rangos de calificaciones
    final rangos = [
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

    // Contar alumnos únicos por rango según su promedio general
    for (final calificaciones in calificacionesPorMatricula.values) {
      final promedioAlumno = calificaciones.reduce((a, b) => a + b) / calificaciones.length;
      
      bool asignado = false;
      for (final rango in rangos) {
        if (rango.$1 != 'Sin Calificar' && 
            promedioAlumno >= rango.$2 && 
            promedioAlumno <= rango.$3) {
          contadores[rango.$1] = contadores[rango.$1]! + 1;
          asignado = true;
          break;
        }
      }
      if (!asignado && promedioAlumno >= 0) {
        // Fallback para valores fuera de rango
        contadores['9.0-10.0'] = contadores['9.0-10.0']! + 1;
      }
    }

    // Agregar alumnos sin calificar
    contadores['Sin Calificar'] = alumnosSinCalificar;

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