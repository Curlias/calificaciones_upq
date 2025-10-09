import 'alumno.dart';
import 'grupo.dart';

class ReporteAlumno {
  final Alumno alumno;
  final double? calificacionFinal;
  final List<double?> calificacionesParciales;
  final bool aprueba;
  final String estadoAcademico;
  final DateTime fechaGeneracion;

  ReporteAlumno({
    required this.alumno,
    required this.fechaGeneracion,
  })  : calificacionFinal = alumno.calcularCalificacionFinalCalculada(),
        calificacionesParciales = [
          alumno.calcularCalificacionParcial(1),
          alumno.calcularCalificacionParcial(2),
          alumno.calcularCalificacionParcial(3),
        ],
        aprueba = alumno.aprueba(),
        estadoAcademico = alumno.estadoAcademico;

  Map<String, dynamic> toMap() {
    return {
      'alumno': alumno.nombre,
      'matricula': alumno.matricula,
      'materia': alumno.nombreMateria,
      'grupo': alumno.grupo,
      'profesor': alumno.nombreProfesor,
      'tutor': alumno.nombreTutor,
      'calificacionFinal': calificacionFinal,
      'calificacionesParciales': calificacionesParciales,
      'aprueba': aprueba,
      'estadoAcademico': estadoAcademico,
      'totalFaltas': alumno.totalFaltas,
      'esRecursamiento': alumno.esRecursamiento,
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
    };
  }
}

class ReporteGrupo {
  final Grupo grupo;
  final double promedioGeneral;
  final int totalAlumnos;
  final int aprobados;
  final int reprobados;
  final int sinCalificar;
  final double porcentajeAprobados;
  final double porcentajeReprobados;
  final Map<int, Map<String, double>> estadisticasPorParcial;
  final Map<String, int> distribucionPorGenero;
  final double promedioFaltas;
  final int alumnosRecursamiento;
  final DateTime fechaGeneracion;

  ReporteGrupo({
    required this.grupo,
    required this.fechaGeneracion,
  })  : promedioGeneral = grupo.promedioGeneral,
        totalAlumnos = grupo.totalAlumnos,
        aprobados = grupo.aprobados(),
        reprobados = grupo.reprobados(),
        sinCalificar = grupo.sinCalificar(),
        porcentajeAprobados = grupo.porcentajeAprobados(),
        porcentajeReprobados = grupo.porcentajeReprobados(),
        estadisticasPorParcial = grupo.estadisticasPorParcial,
        distribucionPorGenero = grupo.distribucionPorGenero,
        promedioFaltas = grupo.promedioFaltas,
        alumnosRecursamiento = grupo.alumnosRecursamiento.length;

  Map<String, dynamic> toMap() {
    return {
      'grupo': grupo.nombre,
      'materia': grupo.nombreMateria,
      'profesor': grupo.nombreProfesor,
      'promedioGeneral': promedioGeneral,
      'totalAlumnos': totalAlumnos,
      'aprobados': aprobados,
      'reprobados': reprobados,
      'sinCalificar': sinCalificar,
      'porcentajeAprobados': porcentajeAprobados,
      'porcentajeReprobados': porcentajeReprobados,
      'estadisticasPorParcial': estadisticasPorParcial,
      'distribucionPorGenero': distribucionPorGenero,
      'promedioFaltas': promedioFaltas,
      'alumnosRecursamiento': alumnosRecursamiento,
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
    };
  }
}

class ReporteGeneral {
  final List<Grupo> grupos;
  final int totalAlumnos;
  final int totalGrupos;
  final int totalMaterias;
  final double promedioGeneralInstitucional;
  final int totalAprobados;
  final int totalReprobados;
  final int totalSinCalificar;
  final double porcentajeAprobadosInstitucional;
  final Map<String, int> distribucionPorCarrera;
  final Map<String, int> distribucionPorGenero;
  final Map<String, double> promediosPorMateria;
  final DateTime fechaGeneracion;

  ReporteGeneral({
    required this.grupos,
    required this.fechaGeneracion,
  })  : totalGrupos = grupos.length,
        totalMaterias = grupos.map((g) => g.nombreMateria).toSet().length,
        totalAlumnos = _calcularTotalAlumnos(grupos),
        promedioGeneralInstitucional = _calcularPromedioGeneral(grupos),
        totalAprobados = _calcularTotalAprobados(grupos),
        totalReprobados = _calcularTotalReprobados(grupos),
        totalSinCalificar = _calcularTotalSinCalificar(grupos),
        porcentajeAprobadosInstitucional = _calcularPorcentajeAprobados(grupos),
        distribucionPorCarrera = _calcularDistribucionPorCarrera(grupos),
        distribucionPorGenero = _calcularDistribucionPorGenero(grupos),
        promediosPorMateria = _calcularPromediosPorMateria(grupos);

  static int _calcularTotalAlumnos(List<Grupo> grupos) {
    final Set<String> alumnosUnicos = {};
    for (final grupo in grupos) {
      for (final alumno in grupo.alumnos) {
        alumnosUnicos.add('${alumno.matricula}_${alumno.nombreMateria}');
      }
    }
    return alumnosUnicos.length;
  }

  static double _calcularPromedioGeneral(List<Grupo> grupos) {
    final List<double> calificaciones = [];
    for (final grupo in grupos) {
      for (final alumno in grupo.alumnos) {
        final cal = alumno.calcularCalificacionFinalCalculada();
        if (cal != null) calificaciones.add(cal);
      }
    }
    if (calificaciones.isEmpty) return 0.0;
    return calificaciones.reduce((a, b) => a + b) / calificaciones.length;
  }

  static int _calcularTotalAprobados(List<Grupo> grupos) {
    int total = 0;
    for (final grupo in grupos) {
      total += grupo.aprobados();
    }
    return total;
  }

  static int _calcularTotalReprobados(List<Grupo> grupos) {
    int total = 0;
    for (final grupo in grupos) {
      total += grupo.reprobados();
    }
    return total;
  }

  static int _calcularTotalSinCalificar(List<Grupo> grupos) {
    int total = 0;
    for (final grupo in grupos) {
      total += grupo.sinCalificar();
    }
    return total;
  }

  static double _calcularPorcentajeAprobados(List<Grupo> grupos) {
    final totalAlumnos = _calcularTotalAlumnos(grupos);
    if (totalAlumnos == 0) return 0.0;
    final totalAprobados = _calcularTotalAprobados(grupos);
    return (totalAprobados / totalAlumnos) * 100;
  }

  static Map<String, int> _calcularDistribucionPorCarrera(List<Grupo> grupos) {
    Map<String, int> distribucion = {};
    for (final grupo in grupos) {
      for (final alumno in grupo.alumnos) {
        distribucion[alumno.carrera] = (distribucion[alumno.carrera] ?? 0) + 1;
      }
    }
    return distribucion;
  }

  static Map<String, int> _calcularDistribucionPorGenero(List<Grupo> grupos) {
    Map<String, int> distribucion = {};
    for (final grupo in grupos) {
      for (final alumno in grupo.alumnos) {
        distribucion[alumno.genero] = (distribucion[alumno.genero] ?? 0) + 1;
      }
    }
    return distribucion;
  }

  static Map<String, double> _calcularPromediosPorMateria(List<Grupo> grupos) {
    Map<String, List<double>> calificacionesPorMateria = {};
    
    for (final grupo in grupos) {
      for (final alumno in grupo.alumnos) {
        final cal = alumno.calcularCalificacionFinalCalculada();
        if (cal != null) {
          calificacionesPorMateria.putIfAbsent(alumno.nombreMateria, () => []);
          calificacionesPorMateria[alumno.nombreMateria]!.add(cal);
        }
      }
    }
    
    Map<String, double> promedios = {};
    calificacionesPorMateria.forEach((materia, calificaciones) {
      if (calificaciones.isNotEmpty) {
        promedios[materia] = calificaciones.reduce((a, b) => a + b) / calificaciones.length;
      }
    });
    
    return promedios;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAlumnos': totalAlumnos,
      'totalGrupos': totalGrupos,
      'totalMaterias': totalMaterias,
      'promedioGeneralInstitucional': promedioGeneralInstitucional,
      'totalAprobados': totalAprobados,
      'totalReprobados': totalReprobados,
      'totalSinCalificar': totalSinCalificar,
      'porcentajeAprobadosInstitucional': porcentajeAprobadosInstitucional,
      'distribucionPorCarrera': distribucionPorCarrera,
      'distribucionPorGenero': distribucionPorGenero,
      'promediosPorMateria': promediosPorMateria,
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
    };
  }
}