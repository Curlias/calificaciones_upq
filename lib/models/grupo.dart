import 'alumno.dart';

class Grupo {
  final String nombre;
  final String materia;
  final String profesor;
  final String carrera;
  final List<Alumno> alumnos;

  Grupo({
    required this.nombre,
    required this.materia,
    required this.profesor,
    required this.carrera,
    required this.alumnos,
  });

  double get promedioGeneral {
    final calificaciones = alumnos
        .map((a) => a.calcularCalificacionFinalCalculada())
        .where((cal) => cal != null)
        .cast<double>()
        .toList();
    
    if (calificaciones.isEmpty) return 0.0;
    
    return calificaciones.reduce((a, b) => a + b) / calificaciones.length;
  }

  int aprobados([double umbral = 7.0]) {
    return alumnos.where((a) => a.aprueba(umbral)).length;
  }

  int reprobados([double umbral = 7.0]) {
    return alumnos.where((a) {
      final cal = a.calcularCalificacionFinalCalculada();
      return cal != null && cal < umbral;
    }).length;
  }

  int sinCalificar() {
    return alumnos.where((a) => a.calcularCalificacionFinalCalculada() == null).length;
  }

  double porcentajeAprobados([double umbral = 7.0]) {
    if (alumnos.isEmpty) return 0.0;
    return (aprobados(umbral) / alumnos.length) * 100;
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
  int get totalAlumnos => alumnos.length;

  double porcentajeReprobados([double umbral = 7.0]) {
    if (alumnos.isEmpty) return 0.0;
    return (reprobados(umbral) / alumnos.length) * 100;
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
