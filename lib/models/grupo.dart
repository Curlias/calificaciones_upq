import 'dart:math';
import 'alumno.dart';

class Grupo {
  final String nombre;
  final String materia;
  final String profesor;
  final String? tutor;
  final String carrera;
  final List<Alumno> alumnos;

  Grupo({
    required this.nombre,
    required this.materia,
    required this.profesor,
    this.tutor,
    required this.carrera,
    required this.alumnos,
  });

  double get promedioGeneral {
    // Agrupar por matrícula y calcular promedio individual
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
    
    if (calificacionesPorMatricula.isEmpty) return 0.0;
    
    // Calcular promedio de cada alumno y luego el promedio general
    final promediosAlumnos = calificacionesPorMatricula.values
        .map((cals) => cals.reduce((a, b) => a + b) / cals.length)
        .toList();
    
    return promediosAlumnos.reduce((a, b) => a + b) / promediosAlumnos.length;
  }

  int aprobados([double umbral = 7.0]) {
    // Contar alumnos únicos con promedio >= umbral
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
    
    int count = 0;
    for (final cals in calificacionesPorMatricula.values) {
      final promedio = cals.reduce((a, b) => a + b) / cals.length;
      if (promedio >= umbral) count++;
    }
    
    return count;
  }

  int reprobados([double umbral = 7.0]) {
    // Contar alumnos únicos con promedio < umbral
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
    
    int count = 0;
    for (final cals in calificacionesPorMatricula.values) {
      final promedio = cals.reduce((a, b) => a + b) / cals.length;
      if (promedio < umbral) count++;
    }
    
    return count;
  }

  int sinCalificar() {
    // Alumnos únicos sin ninguna calificación
    final matriculasConCal = alumnos
        .where((a) => a.calcularCalificacionFinalCalculada() != null)
        .map((a) => a.matricula)
        .toSet();
    
    final todasMatriculas = alumnos.map((a) => a.matricula).toSet();
    
    return todasMatriculas.difference(matriculasConCal).length;
  }

  double porcentajeAprobados([double umbral = 7.0]) {
    final total = totalAlumnos;
    if (total == 0) return 0.0;
    return (aprobados(umbral) / total) * 100;
  }

  double promedioParcial(int parcial) {
    if (parcial < 1 || parcial > 3) return 0.0;
    final calificaciones = alumnos
        .map((a) => a.calcularCalificacionParcial(parcial))
        .where((cal) => cal != null)
        .cast<double>()
        .toList();
    
    if (calificaciones.isEmpty) return 0.0;
    
    return calificaciones.reduce((a, b) => a + b) / calificaciones.length;
  }

  // Getters de compatibilidad
  String get nombreMateria => materia;
  String get nombreProfesor => profesor;
  int get totalAlumnos => alumnos.map((a) => a.matricula).toSet().length; // Matrículas únicas

  double porcentajeReprobados([double umbral = 7.0]) {
    final total = totalAlumnos;
    if (total == 0) return 0.0;
    return (reprobados(umbral) / total) * 100;
  }

  double get promedioFaltas {
    if (alumnos.isEmpty) return 0.0;
    final totalFaltas = alumnos
        .map((a) => a.totalFaltas)
        .reduce((a, b) => a + b);
    return totalFaltas / alumnos.length;
  }

  List<Alumno> get alumnosRecursamiento {
    return alumnos.where((a) => a.esRecursamiento).toList();
  }

  List<Alumno> get alumnosConMasFaltas {
    final sorted = List<Alumno>.from(alumnos);
    sorted.sort((a, b) {
      return b.totalFaltas.compareTo(a.totalFaltas);
    });
    return sorted.take(5).toList();
  }

  List<Alumno> get alumnosOrdenadosPorCalificacion {
    final sorted = List<Alumno>.from(alumnos);
    sorted.sort((a, b) {
      final calA = a.calcularCalificacionFinalCalculada() ?? 0.0;
      final calB = b.calcularCalificacionFinalCalculada() ?? 0.0;
      return calB.compareTo(calA);
    });
    return sorted;
  }

  Map<String, int> get distribucionPorGenero {
    final hombres = alumnos.where((a) => a.genero.toUpperCase() == 'M').length;
    final mujeres = alumnos.where((a) => a.genero.toUpperCase() == 'F').length;
    return {'hombres': hombres, 'mujeres': mujeres};
  }

  /// Distribución de alumnos por rango de calificación
  Map<String, int> get distribucionRangos {
    final dist = <String, int>{'0–5': 0, '5–7': 0, '7–8': 0, '8–9': 0, '9–10': 0, 'S/C': 0};
    final vistos = <String>{};
    for (final alumno in alumnos) {
      if (vistos.contains(alumno.matricula)) continue;
      vistos.add(alumno.matricula);
      final rango = alumno.rangoCalificacion;
      dist[rango] = (dist[rango] ?? 0) + 1;
    }
    return dist;
  }

  /// Alumnos en riesgo (2+ faltas o 2+ parciales reprobados)
  List<Alumno> get alumnosEnRiesgo {
    final vistos = <String>{};
    return alumnos.where((a) {
      if (vistos.contains(a.matricula)) return false;
      vistos.add(a.matricula);
      return a.estaEnRiesgo;
    }).toList();
  }

  /// Alumnos que necesitan extraordinario (5.0 ≤ cal < 7.0)
  List<Alumno> get alumnosNecesitanExtraordinario {
    final vistos = <String>{};
    return alumnos.where((a) {
      if (vistos.contains(a.matricula)) return false;
      vistos.add(a.matricula);
      return a.necesitaExtraordinario;
    }).toList();
  }

  /// Tasa de reprobación por parcial (1, 2, 3) en porcentaje
  Map<int, double> get tasaReprobacionPorParcial {
    final result = <int, double>{};
    for (int i = 1; i <= 3; i++) {
      final conCal = alumnos.where((a) => a.calcularCalificacionParcial(i) != null).toList();
      if (conCal.isEmpty) {
        result[i] = 0.0;
      } else {
        final reprobados = conCal.where((a) => a.calcularCalificacionParcial(i)! < 7.0).length;
        result[i] = (reprobados / conCal.length) * 100;
      }
    }
    return result;
  }

  /// Porcentaje de alumnos sin ninguna calificación capturada (NP)
  double get tasaNoPresentados {
    if (alumnos.isEmpty) return 0.0;
    final sinCal = alumnos.where((a) => a.calcularCalificacionFinalCalculada() == null).length;
    return (sinCal / alumnos.length) * 100;
  }

  /// Correlación de Pearson entre faltas y calificación final (-1 a 1)
  double get correlacionFaltasCalificacion {
    final datos = alumnos.where((a) => a.calcularCalificacionFinalCalculada() != null).toList();
    if (datos.length < 2) return 0.0;

    final n = datos.length.toDouble();
    final faltas = datos.map((a) => a.totalFaltas.toDouble()).toList();
    final cals = datos.map((a) => a.calcularCalificacionFinalCalculada()!).toList();

    final meanF = faltas.reduce((a, b) => a + b) / n;
    final meanC = cals.reduce((a, b) => a + b) / n;

    double num = 0, dF = 0, dC = 0;
    for (int i = 0; i < datos.length; i++) {
      num += (faltas[i] - meanF) * (cals[i] - meanC);
      dF += pow(faltas[i] - meanF, 2);
      dC += pow(cals[i] - meanC, 2);
    }
    final den = sqrt(dF * dC);
    return den == 0 ? 0.0 : num / den;
  }

  /// Porcentaje que necesita extraordinario
  double get porcentajeExtraordinario {
    final total = totalAlumnos;
    if (total == 0) return 0.0;
    return (alumnosNecesitanExtraordinario.length / total) * 100;
  }

  /// Parcial con mayor tasa de reprobación
  int get parcialMasDificil {
    final tasas = tasaReprobacionPorParcial;
    return tasas.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<int, Map<String, double>> get estadisticasPorParcial {
    final stats = <int, Map<String, double>>{};
    
    for (int i = 1; i <= 3; i++) {
      stats[i] = {
        'promedio': promedioParcial(i),
        'aprobados': alumnos.where((a) {
          final cal = a.calcularCalificacionParcial(i);
          return cal != null && cal >= 7.0;
        }).length.toDouble(),
      };
    }
    
    return stats;
  }
}
