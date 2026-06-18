import 'package:flutter/material.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';
import '../services/excel_service.dart';
import '../services/storage_service.dart';

enum EstadoCarga { inicial, cargando, cargado, error }

class DataProvider extends ChangeNotifier {
  // Estado de los datos
  EstadoCarga _estadoCarga = EstadoCarga.inicial;
  List<Alumno> _alumnos = [];
  List<Grupo> _grupos = [];
  String _mensajeError = '';
  String _archivoActual = '';
  DateTime? _fechaUltimaCarga;
  String _informeActualId = '';
  String _informeActualNombre = '';

  // Cache para búsquedas y filtros
  List<Alumno> _alumnosFiltrados = [];
  List<Grupo> _gruposFiltrados = [];
  String _terminoBusqueda = '';

  // Estadísticas generales
  int _totalAlumnos = 0;
  int _totalGrupos = 0;
  int _totalMaterias = 0;
  double _promedioGeneral = 0.0;
  int _totalAprobados = 0;
  int _totalReprobados = 0;
  int _totalSinCalificar = 0;

  // Getters
  EstadoCarga get estadoCarga => _estadoCarga;
  List<Alumno> get alumnos => _alumnos;
  List<Grupo> get grupos => _grupos;
  List<Alumno> get alumnosFiltrados => _alumnosFiltrados;
  List<Grupo> get gruposFiltrados => _gruposFiltrados;
  String get mensajeError => _mensajeError;
  String get archivoActual => _archivoActual;
  DateTime? get fechaUltimaCarga => _fechaUltimaCarga;
  String get terminoBusqueda => _terminoBusqueda;
  String get informeActualId => _informeActualId;
  String get informeActualNombre => _informeActualNombre;

  // Estadísticas
  int get totalAlumnos => _totalAlumnos;
  int get totalGrupos => _totalGrupos;
  int get totalMaterias => _totalMaterias;
  double get promedioGeneral => _promedioGeneral;
  int get totalAprobados => _totalAprobados;
  int get totalReprobados => _totalReprobados;
  int get totalSinCalificar => _totalSinCalificar;

  bool get tieneDatos => _alumnos.isNotEmpty;
  bool get estaCargando => _estadoCarga == EstadoCarga.cargando;
  bool get tieneError => _estadoCarga == EstadoCarga.error;

  /// Carga datos desde un archivo Excel
  Future<bool> cargarDatosDesdeExcel(
    String rutaArchivo, {
    String? sheetName,
    Map<String, int>? columnMapping,
  }) async {
    _estadoCarga = EstadoCarga.cargando;
    _mensajeError = '';
    notifyListeners();

    try {
      final resultado = await ExcelService.parseExcelFile(
        rutaArchivo,
        sheetName: sheetName,
        columnMapping: columnMapping,
      );
      
      if (resultado['success'] == true) {
        _alumnos = List<Alumno>.from(resultado['alumnos']);
        _grupos = List<Grupo>.from(resultado['grupos']);
        _archivoActual = rutaArchivo;
        _fechaUltimaCarga = DateTime.now();
        
        _calcularEstadisticas();
        _aplicarFiltros();
        
        _estadoCarga = EstadoCarga.cargado;
        notifyListeners();
        
        // Guardar informe automáticamente
        await _guardarInformeActual();
        
        return true;
      } else {
        _mensajeError = resultado['message'];
        _estadoCarga = EstadoCarga.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mensajeError = 'Error inesperado: ${e.toString()}';
      _estadoCarga = EstadoCarga.error;
      notifyListeners();
      return false;
    }
  }

  /// Busca alumnos por término
  void buscarAlumnos(String termino) {
    _terminoBusqueda = termino;
    _aplicarFiltros();
    notifyListeners();
  }

  /// Filtra datos según configuración
  void aplicarFiltros({
    bool? soloAprobados,
    bool? soloReprobados,
    bool? soloRecursamiento,
    String? carrera,
    String? materia,
    double umbral = 7.0,
  }) {
    _alumnosFiltrados = List.from(_alumnos);
    _gruposFiltrados = List.from(_grupos);

    // Aplicar filtro de búsqueda
    if (_terminoBusqueda.isNotEmpty) {
      final terminoLower = _terminoBusqueda.toLowerCase();
      _alumnosFiltrados = _alumnosFiltrados.where((alumno) {
        return alumno.nombre.toLowerCase().contains(terminoLower) ||
               alumno.matricula.toLowerCase().contains(terminoLower) ||
               alumno.nombreMateria.toLowerCase().contains(terminoLower) ||
               alumno.grupo.toLowerCase().contains(terminoLower);
      }).toList();
    }

    // Aplicar filtros de estado académico
    if (soloAprobados == true) {
      _alumnosFiltrados = _alumnosFiltrados.where((a) => a.aprueba(umbral)).toList();
    } else if (soloReprobados == true) {
      _alumnosFiltrados = _alumnosFiltrados.where((a) {
        final cal = a.calcularCalificacionFinalCalculada();
        return cal != null && cal < umbral;
      }).toList();
    }

    // Filtro de recursamiento
    if (soloRecursamiento == true) {
      _alumnosFiltrados = _alumnosFiltrados.where((a) => a.esRecursamiento).toList();
    }

    // Filtros por carrera y materia
    if (carrera != null && carrera.isNotEmpty) {
      _alumnosFiltrados = _alumnosFiltrados.where((a) => a.carrera == carrera).toList();
    }

    if (materia != null && materia.isNotEmpty) {
      _alumnosFiltrados = _alumnosFiltrados.where((a) => a.nombreMateria == materia).toList();
    }

    // Filtrar grupos basándose en alumnos filtrados
    final materiasGruposFiltrados = _alumnosFiltrados
        .map((a) => '${a.grupo}_${a.nombreMateria}')
        .toSet();

    _gruposFiltrados = _gruposFiltrados.where((grupo) {
      final claveGrupo = '${grupo.nombre}_${grupo.materia}';
      return materiasGruposFiltrados.contains(claveGrupo);
    }).toList();

    notifyListeners();
  }

  /// Aplica filtros actuales (internos)
  void _aplicarFiltros() => aplicarFiltros();

  /// Sincroniza y aplica los filtros definidos en ConfigProvider
  void sincronizarFiltros({
    bool soloAprobados = false,
    bool soloReprobados = false,
    bool soloRecursamiento = false,
    String carrera = '',
    String materia = '',
    double umbral = 7.0,
  }) {
    aplicarFiltros(
      soloAprobados: soloAprobados,
      soloReprobados: soloReprobados,
      soloRecursamiento: soloRecursamiento,
      carrera: carrera.isNotEmpty ? carrera : null,
      materia: materia.isNotEmpty ? materia : null,
      umbral: umbral,
    );
  }

  /// Calcula estadísticas generales
  void _calcularEstadisticas() {
    if (_alumnos.isEmpty) {
      _totalAlumnos = 0;
      _totalGrupos = 0;
      _totalMaterias = 0;
      _promedioGeneral = 0.0;
      _totalAprobados = 0;
      _totalReprobados = 0;
      _totalSinCalificar = 0;
      return;
    }

    // Agrupar alumnos por matrícula
    final Map<String, List<double>> calificacionesPorMatricula = {};
    
    for (final alumno in _alumnos) {
      final cal = alumno.calcularCalificacionFinalCalculada();
      if (cal != null) {
        if (!calificacionesPorMatricula.containsKey(alumno.matricula)) {
          calificacionesPorMatricula[alumno.matricula] = [];
        }
        calificacionesPorMatricula[alumno.matricula]!.add(cal);
      }
    }

    // Contar alumnos únicos
    final Set<String> alumnosUnicos = _alumnos.map((a) => a.matricula).toSet();
    _totalAlumnos = alumnosUnicos.length;

    _totalGrupos = _grupos.length;
    _totalMaterias = _alumnos.map((a) => a.nombreMateria).toSet().length;

    // Calcular promedio general por alumno (promedio de sus materias)
    final List<double> promediosPorAlumno = [];
    final Set<String> aprobadosUnicos = {};
    final Set<String> reprobadosUnicos = {};
    
    for (final matricula in calificacionesPorMatricula.keys) {
      final cals = calificacionesPorMatricula[matricula]!;
      final promedioAlumno = cals.reduce((a, b) => a + b) / cals.length;
      promediosPorAlumno.add(promedioAlumno);
      
      // Determinar si aprueba o reprueba basado en su promedio general
      if (promedioAlumno >= 7.0) {
        aprobadosUnicos.add(matricula);
      } else {
        reprobadosUnicos.add(matricula);
      }
    }

    // Alumnos sin calificar (no tienen ninguna calificación en ninguna materia)
    final Set<String> sinCalificarUnicos = alumnosUnicos
        .where((matricula) => !calificacionesPorMatricula.containsKey(matricula))
        .toSet();

    _promedioGeneral = promediosPorAlumno.isEmpty 
        ? 0.0 
        : promediosPorAlumno.reduce((a, b) => a + b) / promediosPorAlumno.length;
    
    _totalAprobados = aprobadosUnicos.length;
    _totalReprobados = reprobadosUnicos.length;
    _totalSinCalificar = sinCalificarUnicos.length;
  }

  /// Obtiene un alumno por ID y materia
  Alumno? obtenerAlumnoPorId(String id, String materia) {
    try {
      return _alumnos.firstWhere(
        (alumno) => alumno.id == id && alumno.nombreMateria == materia,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un grupo por nombre y materia
  Grupo? obtenerGrupoPorNombre(String nombre, String materia) {
    try {
      return _grupos.firstWhere(
        (grupo) => grupo.nombre == nombre && grupo.materia == materia,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene lista de carreras únicas
  List<String> get carreras {
    return _alumnos.map((a) => a.carrera).toSet().toList()..sort();
  }

  /// Obtiene lista de materias únicas
  List<String> get materias {
    return _alumnos.map((a) => a.nombreMateria).toSet().toList()..sort();
  }

  /// Obtiene lista de grupos únicos
  List<String> get gruposUnicos {
    return _alumnos.map((a) => a.grupo).toSet().toList()..sort();
  }

  /// Todos los alumnos únicos en riesgo (sin duplicar por materia)
  List<Alumno> get alumnosEnRiesgoGlobal {
    final vistos = <String>{};
    return _alumnos.where((a) {
      if (vistos.contains(a.matricula)) return false;
      vistos.add(a.matricula);
      return a.estaEnRiesgo;
    }).toList()
      ..sort((a, b) => b.totalFaltas.compareTo(a.totalFaltas));
  }

  /// Lista de materias ordenadas por dificultad (promedio más bajo primero)
  List<Map<String, dynamic>> get materiasPorDificultad {
    final Map<String, List<double>> calsPorMateria = {};
    for (final a in _alumnos) {
      final cal = a.calcularCalificacionFinalCalculada();
      if (cal != null) {
        calsPorMateria.putIfAbsent(a.nombreMateria, () => []).add(cal);
      }
    }
    final result = calsPorMateria.entries.map((e) {
      final prom = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'materia': e.key, 'promedio': prom, 'total': e.value.length};
    }).toList();
    result.sort((a, b) => (a['promedio'] as double).compareTo(b['promedio'] as double));
    return result;
  }

  /// Distribución global por rangos de calificación
  Map<String, int> get distribucionRangosGlobal {
    final dist = <String, int>{'0–5': 0, '5–7': 0, '7–8': 0, '8–9': 0, '9–10': 0, 'S/C': 0};
    final vistos = <String>{};
    for (final a in _alumnos) {
      final key = '${a.matricula}_${a.nombreMateria}';
      if (vistos.contains(key)) continue;
      vistos.add(key);
      dist[a.rangoCalificacion] = (dist[a.rangoCalificacion] ?? 0) + 1;
    }
    return dist;
  }

  /// Total de alumnos que necesitan extraordinario
  int get totalNecesitanExtraordinario {
    final vistos = <String>{};
    return _alumnos.where((a) {
      final key = '${a.matricula}_${a.nombreMateria}';
      if (vistos.contains(key)) return false;
      vistos.add(key);
      return a.necesitaExtraordinario;
    }).length;
  }

  /// Obtiene estadísticas por carrera
  Map<String, Map<String, dynamic>> get estadisticasPorCarrera {
    // Agrupar alumnos por carrera y matrícula
    final Map<String, Map<String, List<double>>> alumnosPorCarrera = {};
    
    for (final alumno in _alumnos) {
      if (!alumnosPorCarrera.containsKey(alumno.carrera)) {
        alumnosPorCarrera[alumno.carrera] = {};
      }
      
      final cal = alumno.calcularCalificacionFinalCalculada();
      if (cal != null) {
        if (!alumnosPorCarrera[alumno.carrera]!.containsKey(alumno.matricula)) {
          alumnosPorCarrera[alumno.carrera]![alumno.matricula] = [];
        }
        alumnosPorCarrera[alumno.carrera]![alumno.matricula]!.add(cal);
      }
    }

    final Map<String, Map<String, dynamic>> estadisticas = {};
    
    alumnosPorCarrera.forEach((carrera, matriculasConCalificaciones) {
      final List<double> promediosPorAlumno = [];
      int aprobados = 0;
      int reprobados = 0;
      
      for (final calificaciones in matriculasConCalificaciones.values) {
        final promedioAlumno = calificaciones.reduce((a, b) => a + b) / calificaciones.length;
        promediosPorAlumno.add(promedioAlumno);
        
        if (promedioAlumno >= 7.0) {
          aprobados++;
        } else {
          reprobados++;
        }
      }
      
      final promedio = promediosPorAlumno.isEmpty 
          ? 0.0 
          : promediosPorAlumno.reduce((a, b) => a + b) / promediosPorAlumno.length;
      
      final totalAlumnosUnicos = matriculasConCalificaciones.length;

      estadisticas[carrera] = {
        'totalAlumnos': totalAlumnosUnicos,
        'promedio': promedio,
        'aprobados': aprobados,
        'reprobados': reprobados,
        'porcentajeAprobados': totalAlumnosUnicos == 0 ? 0.0 : (aprobados / totalAlumnosUnicos) * 100,
      };
    });

    return estadisticas;
  }

  /// Limpia todos los datos
  void limpiarDatos() {
    _estadoCarga = EstadoCarga.inicial;
    _alumnos.clear();
    _grupos.clear();
    _alumnosFiltrados.clear();
    _gruposFiltrados.clear();
    _mensajeError = '';
    _archivoActual = '';
    _fechaUltimaCarga = null;
    _terminoBusqueda = '';
    _calcularEstadisticas();
    notifyListeners();
  }

  /// Refresca los datos del archivo actual
  Future<bool> refrescarDatos() async {
    if (_archivoActual.isNotEmpty) {
      return await cargarDatosDesdeExcel(_archivoActual);
    }
    return false;
  }

  /// Guarda el informe actual
  Future<bool> _guardarInformeActual() async {
    if (_alumnos.isEmpty) return false;
    
    final reportId = DateTime.now().millisecondsSinceEpoch.toString();
    final reportName = 'Informe ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    
    final saved = await StorageService.saveReport(
      reportId: reportId,
      reportName: reportName,
      alumnos: _alumnos,
      grupos: _grupos,
    );
    
    if (saved) {
      _informeActualId = reportId;
      _informeActualNombre = reportName;
    }
    
    return saved;
  }

  /// Carga un informe guardado
  Future<bool> cargarInformeGuardado(String reportId) async {
    _estadoCarga = EstadoCarga.cargando;
    _mensajeError = '';
    notifyListeners();

    try {
      final reportData = await StorageService.loadReport(reportId);
      
      if (reportData != null) {
        _alumnos = StorageService.parseAlumnos(reportData['alumnos']);
        _grupos = ExcelService.organizarPorGrupos(_alumnos);
        _archivoActual = reportData['name'];
        _fechaUltimaCarga = DateTime.parse(reportData['createdAt']);
        _informeActualId = reportId;
        _informeActualNombre = reportData['name'];
        
        _calcularEstadisticas();
        _aplicarFiltros();
        
        _estadoCarga = EstadoCarga.cargado;
        notifyListeners();
        return true;
      } else {
        _mensajeError = 'No se pudo cargar el informe';
        _estadoCarga = EstadoCarga.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mensajeError = 'Error al cargar informe: ${e.toString()}';
      _estadoCarga = EstadoCarga.error;
      notifyListeners();
      return false;
    }
  }

  /// Obtiene todas las generaciones disponibles
  List<String> get generacionesDisponibles {
    final generaciones = _alumnos
        .where((a) => a.generacion != null && a.generacion!.isNotEmpty)
        .map((a) => a.generacion!)
        .toSet()
        .toList()
      ..sort();
    return generaciones;
  }

  /// Obtiene grupos de una generación específica
  List<String> gruposPorGeneracion(String generacion) {
    return _alumnos
        .where((a) => a.generacion == generacion)
        .map((a) => a.grupo)
        .toSet()
        .toList()
      ..sort();
  }

  /// Obtiene grupos materia de un grupo específico
  List<String> gruposMateriaDeGrupo(String grupo) {
    return _alumnos
        .where((a) => a.grupo == grupo && a.grupoMateria != null && a.grupoMateria!.isNotEmpty)
        .map((a) => a.grupoMateria!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Obtiene alumnos por generación
  List<Alumno> alumnosPorGeneracion(String generacion) {
    return _alumnos.where((a) => a.generacion == generacion).toList();
  }

  /// Obtiene alumnos por grupo
  List<Alumno> alumnosPorGrupo(String grupo) {
    return _alumnos.where((a) => a.grupo == grupo).toList();
  }

  /// Obtiene alumnos por grupo materia
  List<Alumno> alumnosPorGrupoMateria(String grupoMateria) {
    return _alumnos.where((a) => a.grupoMateria == grupoMateria).toList();
  }

  /// Estadísticas por generación
  Map<String, dynamic> estadisticasPorGeneracion(String generacion) {
    final alumnosGeneracion = alumnosPorGeneracion(generacion);
    
    // Agrupar por matrícula para contar alumnos únicos
    final Map<String, List<double>> calificacionesPorMatricula = {};
    
    for (final alumno in alumnosGeneracion) {
      final cal = alumno.calcularCalificacionFinalCalculada();
      if (cal != null) {
        if (!calificacionesPorMatricula.containsKey(alumno.matricula)) {
          calificacionesPorMatricula[alumno.matricula] = [];
        }
        calificacionesPorMatricula[alumno.matricula]!.add(cal);
      }
    }

    int aprobados = 0;
    int reprobados = 0;
    double sumaPromedios = 0.0;
    
    for (final calificaciones in calificacionesPorMatricula.values) {
      final promedioAlumno = calificaciones.reduce((a, b) => a + b) / calificaciones.length;
      sumaPromedios += promedioAlumno;
      
      if (promedioAlumno >= 7.0) {
        aprobados++;
      } else {
        reprobados++;
      }
    }

    final totalAlumnos = calificacionesPorMatricula.length;
    final sinCalificar = alumnosGeneracion.map((a) => a.matricula).toSet().length - totalAlumnos;

    return {
      'totalAlumnos': totalAlumnos + sinCalificar,
      'aprobados': aprobados,
      'reprobados': reprobados,
      'sinCalificar': sinCalificar,
      'promedioGeneral': totalAlumnos > 0 ? sumaPromedios / totalAlumnos : 0.0,
      'grupos': gruposPorGeneracion(generacion).length,
    };
  }

  /// Detecta recursadores en un grupo materia (alumnos de otras generaciones)
  List<Alumno> detectarRecursadoresEnGrupoMateria(String grupoMateria) {
    final alumnosGrupoMateria = alumnosPorGrupoMateria(grupoMateria);
    
    // Encontrar la generación principal del grupo materia (la más común)
    final generacionesCounts = <String, int>{};
    for (final alumno in alumnosGrupoMateria) {
      if (alumno.generacion != null) {
        generacionesCounts[alumno.generacion!] = (generacionesCounts[alumno.generacion!] ?? 0) + 1;
      }
    }
    
    if (generacionesCounts.isEmpty) return [];
    
    final generacionPrincipal = generacionesCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Retornar alumnos que NO son de la generación principal
    return alumnosGrupoMateria
        .where((a) => a.generacion != null && a.generacion != generacionPrincipal)
        .toList();
  }
}
