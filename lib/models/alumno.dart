class Alumno {
  final String id;
  final String matricula;
  final String nombre;
  final String genero;
  final String carrera;
  final String grupo;
  final String nombreMateria;
  final String nombreProfesor;
  final String? nombreTutor;
  final bool esRecursamiento;
  
  // Calificaciones
  final double? parcial1;
  final double? parcial2;
  final double? parcial3;
  final double? parcialFinal1;
  final double? parcialFinal2;
  final double? parcialFinal3;
  
  // Faltas
  final int faltasP1;
  final int faltasP2;
  final int faltasP3;

  Alumno({
    required this.id,
    required this.matricula,
    required this.nombre,
    required this.genero,
    required this.carrera,
    required this.grupo,
    required this.nombreMateria,
    required this.nombreProfesor,
    this.nombreTutor,
    this.esRecursamiento = false,
    this.parcial1,
    this.parcial2,
    this.parcial3,
    this.parcialFinal1,
    this.parcialFinal2,
    this.parcialFinal3,
    this.faltasP1 = 0,
    this.faltasP2 = 0,
    this.faltasP3 = 0,
  });

  /// Calcula la calificación de un parcial específico
  /// Si el parcial >= 7: promedio (parcial + final) / 2
  /// Si el parcial < 7: usar solo parcial final
  double? calcularCalificacionParcial(int numeroParcial) {
    double? parcial;
    double? parcialFinal;
    
    switch (numeroParcial) {
      case 1:
        parcial = this.parcial1;
        parcialFinal = parcialFinal1;
        break;
      case 2:
        parcial = this.parcial2;
        parcialFinal = parcialFinal2;
        break;
      case 3:
        parcial = this.parcial3;
        parcialFinal = parcialFinal3;
        break;
      default:
        return null;
    }

    if (parcial == null) return null;
    
    // Si el parcial se reprobó (< 7), usar solo el parcial final
    if (parcial < 7.0) {
      return parcialFinal;
    }
    
    // Si se aprobó el parcial, promediar con el final
    if (parcialFinal != null) {
      return (parcial + parcialFinal) / 2;
    }
    
    return parcial;
  }

  /// Calcula la calificación final promediando los parciales
  double? calcularCalificacionFinalCalculada() {
    List<double> calificaciones = [];
    
    for (int i = 1; i <= 3; i++) {
      final cal = calcularCalificacionParcial(i);
      if (cal != null) {
        calificaciones.add(cal);
      }
    }
    
    if (calificaciones.isEmpty) return null;
    
    return calificaciones.reduce((a, b) => a + b) / calificaciones.length;
  }

  /// Determina si el alumno aprueba la materia (umbral >= 7.0)
  bool aprueba([double umbral = 7.0]) {
    final calFinal = calcularCalificacionFinalCalculada();
    return calFinal != null && calFinal >= umbral;
  }

  /// Determina si aprueba un parcial específico
  bool apruebaParcial(int numeroParcial, [double umbral = 7.0]) {
    final cal = calcularCalificacionParcial(numeroParcial);
    return cal != null && cal >= umbral;
  }

  /// Obtiene el total de faltas
  int get totalFaltas => faltasP1 + faltasP2 + faltasP3;

  /// Obtiene una descripción del estado académico
  String get estadoAcademico {
    if (aprueba()) return 'Aprobado';
    if (calcularCalificacionFinalCalculada() != null) return 'Reprobado';
    return 'Sin calificar';
  }

  @override
  String toString() {
    return 'Alumno{nombre: $nombre, matricula: $matricula, materia: $nombreMateria, grupo: $grupo}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alumno &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          matricula == other.matricula &&
          nombreMateria == other.nombreMateria;

  @override
  int get hashCode => id.hashCode ^ matricula.hashCode ^ nombreMateria.hashCode;
}
