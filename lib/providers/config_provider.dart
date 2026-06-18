import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigProvider extends ChangeNotifier {
  static const String _prefsKey = 'config_v1';

  // Configuración de umbral de aprobación
  double _umbralAprobacion = 7.0;

  // Configuración institucional
  String _nombreInstitucion = 'Universidad Politécnica de Querétaro';
  String? _logoPath = 'assets/images/upq_logo.png';

  // Configuración visual
  Color _colorPrimario = const Color(0xFF151830);
  Color _colorSecundario = const Color(0xFF8C2437);
  String _fuenteSeleccionada = 'Roboto';
  bool _modoOscuro = false;
  
  // Configuración de reportes
  bool _incluirLogosEnReportes = true;
  bool _incluirFirmaEnReportes = false;
  String _textoFirma = '';
  
  // Configuración de filtros
  bool _mostrarSoloAprobados = false;
  bool _mostrarSoloReprobados = false;
  bool _mostrarSoloRecursamiento = false;
  String _filtroCarrera = '';
  String _filtroMateria = '';
  
  // Getters
  double get umbralAprobacion => _umbralAprobacion;
  String get nombreInstitucion => _nombreInstitucion;
  String? get logoPath => _logoPath;
  Color get colorPrimario => _colorPrimario;
  Color get colorSecundario => _colorSecundario;
  String get fuenteSeleccionada => _fuenteSeleccionada;
  bool get incluirLogosEnReportes => _incluirLogosEnReportes;
  bool get incluirFirmaEnReportes => _incluirFirmaEnReportes;
  String get textoFirma => _textoFirma;
  bool get modoOscuro => _modoOscuro;
  bool get mostrarSoloAprobados => _mostrarSoloAprobados;
  bool get mostrarSoloReprobados => _mostrarSoloReprobados;
  bool get mostrarSoloRecursamiento => _mostrarSoloRecursamiento;
  String get filtroCarrera => _filtroCarrera;
  String get filtroMateria => _filtroMateria;

  // Setters con validación
  set umbralAprobacion(double valor) {
    if (valor >= 0.0 && valor <= 10.0) {
      _umbralAprobacion = valor;
      _persistir();
      notifyListeners();
    }
  }

  set nombreInstitucion(String nombre) {
    if (nombre.isNotEmpty) {
      _nombreInstitucion = nombre;
      _persistir();
      notifyListeners();
    }
  }

  set logoPath(String? path) {
    _logoPath = path;
    _persistir();
    notifyListeners();
  }

  set colorPrimario(Color color) {
    _colorPrimario = color;
    _persistir();
    notifyListeners();
  }

  set colorSecundario(Color color) {
    _colorSecundario = color;
    _persistir();
    notifyListeners();
  }

  set fuenteSeleccionada(String fuente) {
    _fuenteSeleccionada = fuente;
    _persistir();
    notifyListeners();
  }

  set incluirLogosEnReportes(bool incluir) {
    _incluirLogosEnReportes = incluir;
    _persistir();
    notifyListeners();
  }

  set incluirFirmaEnReportes(bool incluir) {
    _incluirFirmaEnReportes = incluir;
    _persistir();
    notifyListeners();
  }

  set textoFirma(String texto) {
    _textoFirma = texto;
    _persistir();
    notifyListeners();
  }

  set modoOscuro(bool valor) {
    _modoOscuro = valor;
    _persistir();
    notifyListeners();
  }

  set mostrarSoloAprobados(bool mostrar) {
    if (mostrar) {
      _mostrarSoloReprobados = false;
    }
    _mostrarSoloAprobados = mostrar;
    notifyListeners();
  }

  set mostrarSoloReprobados(bool mostrar) {
    if (mostrar) {
      _mostrarSoloAprobados = false;
    }
    _mostrarSoloReprobados = mostrar;
    notifyListeners();
  }

  set mostrarSoloRecursamiento(bool mostrar) {
    _mostrarSoloRecursamiento = mostrar;
    notifyListeners();
  }

  set filtroCarrera(String carrera) {
    _filtroCarrera = carrera;
    notifyListeners();
  }

  set filtroMateria(String materia) {
    _filtroMateria = materia;
    notifyListeners();
  }

  // Métodos de utilidad
  void limpiarFiltros() {
    _mostrarSoloAprobados = false;
    _mostrarSoloReprobados = false;
    _mostrarSoloRecursamiento = false;
    _filtroCarrera = '';
    _filtroMateria = '';
    notifyListeners();
  }

  void resetearConfiguracion() {
    _umbralAprobacion = 7.0;
    _nombreInstitucion = 'Universidad Politécnica de Querétaro';
    _logoPath = 'assets/images/upq_logo.png';
    _colorPrimario = const Color(0xFF151830);
    _colorSecundario = const Color(0xFF8C2437);
    _fuenteSeleccionada = 'Roboto';
    _modoOscuro = false;
    _incluirLogosEnReportes = true;
    _incluirFirmaEnReportes = false;
    _textoFirma = '';
    limpiarFiltros();
    _persistir();
  }

  /// Persiste la configuración en SharedPreferences
  Future<void> _persistir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _serializarJson());
    } catch (_) {}
  }

  /// Carga la configuración guardada al iniciar la app
  Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        fromMap(map);
      }
    } catch (_) {}
  }

  ThemeData get tema {
    final brightness = _modoOscuro ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _colorPrimario,
        secondary: _colorSecundario,
        brightness: brightness,
      ),
      fontFamily: _fuenteSeleccionada,
      appBarTheme: AppBarTheme(
        backgroundColor: _modoOscuro ? Colors.grey[900] : _colorPrimario,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorPrimario,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.grey[50],
      ),
    );
  }

  // Validación de configuración
  List<String> validarConfiguracion() {
    final errores = <String>[];
    
    if (_umbralAprobacion < 0 || _umbralAprobacion > 10) {
      errores.add('El umbral de aprobación debe estar entre 0 y 10');
    }
    
    if (_nombreInstitucion.isEmpty) {
      errores.add('El nombre de la institución no puede estar vacío');
    }
    
    if (_incluirFirmaEnReportes && _textoFirma.isEmpty) {
      errores.add('Debe proporcionar un texto para la firma si está habilitada');
    }
    
    return errores;
  }

  Map<String, dynamic> toMap() {
    return {
      'umbralAprobacion': _umbralAprobacion,
      'nombreInstitucion': _nombreInstitucion,
      'logoPath': _logoPath,
      'colorPrimario': _colorPrimario.value,
      'colorSecundario': _colorSecundario.value,
      'fuenteSeleccionada': _fuenteSeleccionada,
      'incluirLogosEnReportes': _incluirLogosEnReportes,
      'incluirFirmaEnReportes': _incluirFirmaEnReportes,
      'textoFirma': _textoFirma,
      'modoOscuro': _modoOscuro,
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _umbralAprobacion = (map['umbralAprobacion'] as num?)?.toDouble() ?? 7.0;
    _nombreInstitucion = map['nombreInstitucion'] ?? 'Universidad Politécnica de Querétaro';
    _logoPath = map['logoPath'];
    _colorPrimario = Color(map['colorPrimario'] ?? const Color(0xFF151830).value);
    _colorSecundario = Color(map['colorSecundario'] ?? const Color(0xFF8C2437).value);
    _fuenteSeleccionada = map['fuenteSeleccionada'] ?? 'Roboto';
    _incluirLogosEnReportes = map['incluirLogosEnReportes'] ?? true;
    _incluirFirmaEnReportes = map['incluirFirmaEnReportes'] ?? false;
    _textoFirma = map['textoFirma'] ?? '';
    _modoOscuro = map['modoOscuro'] ?? false;
    notifyListeners();
  }

  String _serializarJson() {
    return jsonEncode(toMap());
  }
}