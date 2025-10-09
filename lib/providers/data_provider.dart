import 'package:flutter/material.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';
import '../services/excel_service.dart';

enum EstadoCarga { inicial, cargando, cargado, error }

class DataProvider extends ChangeNotifier {
  // Estado de los datos
  EstadoCarga _estadoCarga = EstadoCarga.inicial;
  List<Alumno> _alumnos = [];
  List<Grupo> _grupos = [];
  String _mensajeError = '';
  String _archivoActual = '';
  DateTime? _fechaUltimaCarga;

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
  Future<bool> cargarDatosDesdeExcel(String rutaArchivo) async {
    _estadoCarga = EstadoCarga.cargando;
    _mensajeError = '';
    notifyListeners();

    try {
      final resultado = await ExcelService.parseExcelFile(rutaArchivo);
      
      if (resultado['success'] == true) {
        _alumnos = List<Alumno>.from(resultado['alumnos']);
        _grupos = List<Grupo>.from(resultado['grupos']);
        _archivoActual = rutaArchivo;
        _fechaUltimaCarga = DateTime.now();
        
        _calcularEstadisticas();
        _aplicarFiltros();
        
        _estadoCarga = EstadoCarga.cargado;
        notifyListeners();
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

  /// Aplica filtros actuales
  void _aplicarFiltros() {
    aplicarFiltros();
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

    // Contar alumnos únicos por materia
    final Set<String> alumnosUnicos = {};
    for (final alumno in _alumnos) {
      alumnosUnicos.add('${alumno.matricula}_${alumno.nombreMateria}');
    }
    _totalAlumnos = alumnosUnicos.length;

    _totalGrupos = _grupos.length;
    _totalMaterias = _alumnos.map((a) => a.nombreMateria).toSet().length;

    // Calcular promedios y conteos
    final List<double> calificaciones = [];
    int aprobados = 0;
    int reprobados = 0;
    int sinCalificar = 0;

    for (final alumno in _alumnos) {
      final cal = alumno.calcularCalificacionFinalCalculada();
      if (cal != null) {
        calificaciones.add(cal);
        if (cal >= 7.0) {
          aprobados++;
        } else {
          reprobados++;
        }
      } else {
        sinCalificar++;
      }
    }

    _promedioGeneral = calificaciones.isEmpty 
        ? 0.0 
        : calificaciones.reduce((a, b) => a + b) / calificaciones.length;
    
    _totalAprobados = aprobados;
    _totalReprobados = reprobados;
    _totalSinCalificar = sinCalificar;
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

  /// Obtiene estadísticas por carrera
  Map<String, Map<String, dynamic>> get estadisticasPorCarrera {
    final Map<String, List<Alumno>> alumnosPorCarrera = {};
    
    for (final alumno in _alumnos) {
      alumnosPorCarrera.putIfAbsent(alumno.carrera, () => []);
      alumnosPorCarrera[alumno.carrera]!.add(alumno);
    }

    final Map<String, Map<String, dynamic>> estadisticas = {};
    
    alumnosPorCarrera.forEach((carrera, alumnos) {
      final calificaciones = alumnos
          .map((a) => a.calcularCalificacionFinalCalculada())
          .where((cal) => cal != null)
          .cast<double>()
          .toList();
      
      final promedio = calificaciones.isEmpty 
          ? 0.0 
          : calificaciones.reduce((a, b) => a + b) / calificaciones.length;
      
      final aprobados = alumnos.where((a) => a.aprueba()).length;
      final reprobados = alumnos.where((a) {
        final cal = a.calcularCalificacionFinalCalculada();
        return cal != null && cal < 7.0;
      }).length;

      estadisticas[carrera] = {
        'totalAlumnos': alumnos.length,
        'promedio': promedio,
        'aprobados': aprobados,
        'reprobados': reprobados,
        'porcentajeAprobados': alumnos.isEmpty ? 0.0 : (aprobados / alumnos.length) * 100,
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
}