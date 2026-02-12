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
    final hombres = alumnos.where((a) => a.genero.toUpperCase() == 'M' || a.genero.toUpperCase() == 'H').length;
    final mujeres = alumnos.where((a) => a.genero.toUpperCase() == 'F').length;
    return {'hombres': hombres, 'mujeres': mujeres};
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
