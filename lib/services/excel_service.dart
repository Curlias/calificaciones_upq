import 'dart:io';
import 'package:excel/excel.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';

class ExcelService {
  static const String _hojaGruposOfi = 'GruposOfi';

  /// Parsea un archivo Excel y convierte los datos en listas de alumnos y grupos
  static Future<Map<String, dynamic>> parseExcelFile(
    String filePath, {
    String? sheetName,
    Map<String, int>? columnMapping,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      // Usar la hoja especificada o la hoja por defecto
      final targetSheet = sheetName ?? _hojaGruposOfi;
      
      // Verificar que existe la hoja
      if (!excel.tables.containsKey(targetSheet)) {
        throw Exception('No se encontró la hoja "$targetSheet" en el archivo Excel');
      }

      final sheet = excel.tables[targetSheet]!;
      final alumnos = await _parseAlumnos(sheet, columnMapping: columnMapping);
      final grupos = organizarPorGrupos(alumnos);

      return {
        'alumnos': alumnos,
        'grupos': grupos,
        'success': true,
        'message': 'Archivo procesado exitosamente. ${alumnos.length} registros importados.',
      };
    } catch (e) {
      return {
        'alumnos': <Alumno>[],
        'grupos': <Grupo>[],
        'success': false,
        'message': 'Error al procesar el archivo: ${e.toString()}',
      };
    }
  }

  /// Convierte las filas del Excel en objetos Alumno
  static Future<List<Alumno>> _parseAlumnos(Sheet sheet, {Map<String, int>? columnMapping}) async {
    final List<Alumno> alumnos = [];
    final rows = sheet.rows;
    
    // Usar mapeo de columnas proporcionado o el predeterminado
    final mapping = columnMapping ?? _defaultColumnMapping();
    
    if (rows.length < 2) {
      throw Exception('El archivo no contiene datos válidos');
    }

    // Empezar desde la fila 2 (índice 1), asumiendo que la fila 1 son headers
    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        
        // Obtener valores de las celdas usando el mapeo de columnas
        final id = _getCellValue(row, mapping['ID']!) ?? '';
        final matricula = _getCellValue(row, mapping['Matrícula']!) ?? '';
        final nombre = _getCellValue(row, mapping['Nombre']!) ?? '';
        final generoRaw = _getCellValue(row, mapping['Género']!) ?? '';
        final genero = _normalizarGenero(generoRaw);
        final carrera = _getCellValue(row, mapping['Carrera']!) ?? '';
        final generacion = mapping.containsKey('Generación')
            ? _getCellValue(row, mapping['Generación']!)
            : null;
        final grupo = _getCellValue(row, mapping['Grupo']!) ?? '';
        final grupoMateria = mapping.containsKey('Grupo Materia') 
            ? _getCellValue(row, mapping['Grupo Materia']!) 
            : null;
        final nombreMateria = _getCellValue(row, mapping['Materia']!) ?? '';
        
        // Parciales
        final parcial1 = _parseDouble(_getCellValue(row, mapping['Parcial 1']!));
        final parcial2 = _parseDouble(_getCellValue(row, mapping['Parcial 2']!));
        final parcial3 = _parseDouble(_getCellValue(row, mapping['Parcial 3']!));
        
        // Parciales finales
        final parcialFinal1 = _parseDouble(_getCellValue(row, mapping['Parcial Final 1']!));
        final parcialFinal2 = _parseDouble(_getCellValue(row, mapping['Parcial Final 2']!));
        final parcialFinal3 = _parseDouble(_getCellValue(row, mapping['Parcial Final 3']!));
        
        // Faltas
        final faltasP1 = _parseInt(_getCellValue(row, mapping['Faltas P1']!));
        final faltasP2 = _parseInt(_getCellValue(row, mapping['Faltas P2']!));
        final faltasP3 = _parseInt(_getCellValue(row, mapping['Faltas P3']!));
        
        // Otros datos
        final nombreProfesor = _getCellValue(row, mapping['Profesor']!) ?? '';
        final nombreTutor = _getCellValue(row, mapping['Tutor']!);
        final tipoCurso = _getCellValue(row, mapping['Tipo Curso']!) ?? 'N';
        
        final alumno = Alumno(
          id: id,
          matricula: matricula,
          nombre: nombre,
          genero: genero,
          carrera: carrera,
          generacion: generacion,
          grupo: grupo,
          grupoMateria: grupoMateria,
          nombreMateria: nombreMateria,
          nombreProfesor: nombreProfesor,
          nombreTutor: nombreTutor,
          esRecursamiento: tipoCurso == 'R',
          parcial1: parcial1,
          parcialFinal1: parcialFinal1,
          faltasP1: faltasP1,
          parcial2: parcial2,
          parcialFinal2: parcialFinal2,
          faltasP2: faltasP2,
          parcial3: parcial3,
          parcialFinal3: parcialFinal3,
          faltasP3: faltasP3,
        );
        
        alumnos.add(alumno);
      } catch (e) {
        // Continuar con la siguiente fila si hay error
        print('Error en fila ${i + 1}: $e');
      }
    }
    
    return alumnos;
  }

  /// Organiza los alumnos por grupos
  static List<Grupo> organizarPorGrupos(List<Alumno> alumnos) {
    final Map<String, List<Alumno>> gruposMap = {};
    
    for (final alumno in alumnos) {
      // Agrupar solo por el grupo generacional, sin la materia
      final grupoKey = alumno.grupo;
      if (!gruposMap.containsKey(grupoKey)) {
        gruposMap[grupoKey] = [];
      }
      gruposMap[grupoKey]!.add(alumno);
    }
    
    return gruposMap.entries.map((entry) {
      final alumnosGrupo = entry.value;
      // Obtener la primera materia como referencia (o podría ser "Múltiples materias")
      final materiasUnicas = alumnosGrupo.map((a) => a.nombreMateria).toSet();
      final nombreMateria = materiasUnicas.length == 1 
          ? materiasUnicas.first 
          : 'Múltiples materias';
      
      return Grupo(
        nombre: entry.key,
        materia: nombreMateria,
        alumnos: alumnosGrupo,
        profesor: alumnosGrupo.first.nombreProfesor,
        tutor: alumnosGrupo.first.nombreTutor,
        carrera: alumnosGrupo.first.carrera,
      );
    }).toList();
  }

  /// Extrae el grupo generacional del grupo completo
  /// Ejemplo: "IRT201-A" -> "IRT201", "IDIA-M" -> "IDIA"
  static String _extraerGrupoGeneracional(String grupoCompleto) {
    // Buscar patrón: letras seguidas de números (IRT201, IDIA101, etc.)
    final regex = RegExp(r'^([A-Z]+\d+)', caseSensitive: true);
    final match = regex.firstMatch(grupoCompleto);
    if (match != null) {
      return match.group(1)!;
    }
    
    // Si no encuentra patrón, intenta separar por guión o espacio
    if (grupoCompleto.contains('-')) {
      return grupoCompleto.split('-').first.trim();
    }
    if (grupoCompleto.contains(' ')) {
      return grupoCompleto.split(' ').first.trim();
    }
    
    // Si no hay separador, devolver todo
    return grupoCompleto;
  }

  /// Obtiene el valor de una celda como String
  static String? _getCellValue(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null || cell.value == null) return null;
    return cell.value.toString().trim();
  }

  /// Convierte un valor a double
  static double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Convierte un valor a int
  static int _parseInt(String? value) {
    if (value == null || value.isEmpty) return 0;
    try {
      return int.parse(value);
    } catch (e) {
      return 0;
    }
  }

  /// Normaliza el género a M o F
  static String _normalizarGenero(String genero) {
    final generoLower = genero.toLowerCase().trim();
    
    // Masculino: M, masculino, hombre, h, male, man
    if (generoLower.startsWith('m') || generoLower.startsWith('h') || 
        generoLower == 'male' || generoLower == 'man') {
      return 'M';
    }
    
    // Femenino: F, femenino, mujer, m (cuando ya descartamos masculino), female, woman
    if (generoLower.startsWith('f') || generoLower == 'mujer' || 
        generoLower == 'female' || generoLower == 'woman') {
      return 'F';
    }
    
    // Por defecto, devolver el valor original
    return genero.toUpperCase();
  }

  /// Valida la estructura del archivo Excel
  static Future<Map<String, dynamic>> validateExcelStructure(String filePath, {String? sheetName}) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final errors = <String>[];
      final warnings = <String>[];

      // Si se especifica una hoja, validar esa hoja; sino, usar la hoja por defecto
      final targetSheet = sheetName ?? _hojaGruposOfi;
      
      // Verificar que existe la hoja especificada
      if (!excel.tables.containsKey(targetSheet)) {
        errors.add('No se encontró la hoja "$targetSheet"');
      } else {
        final sheet = excel.tables[targetSheet]!;
        final rows = sheet.rows;

        // Verificar que tiene al menos 2 filas (header + data)
        if (rows.length < 2) {
          errors.add('La hoja "$targetSheet" no contiene datos');
        } else {
          final headerRow = rows[0];
          
          // Verificar columnas mínimas requeridas (ajustar según necesidad)
          final requiredColumns = [
            'ID', 'Matricula', 'Alumno', 'Genero', 'Carrera', 'Grupo',
            'Nombre de la Materia', 'Parcial 1', 'Parcial 2', 'Parcial 3'
          ];
          
          for (int i = 0; i < requiredColumns.length && i < headerRow.length; i++) {
            final cellValue = _getCellValue(headerRow, i);
            if (cellValue == null || !cellValue.contains(requiredColumns[i].split(' ')[0])) {
              warnings.add('Columna ${i + 1}: Se esperaba "${requiredColumns[i]}"');
            }
          }
          
          // Advertencia sobre filas
          if (rows.length > 1000) {
            warnings.add('El archivo contiene ${rows.length - 1} filas. El procesamiento puede tardar.');
          }
        }
      }

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
      };
    } catch (e) {
      return {
        'isValid': false,
        'errors': ['Error al validar el archivo: ${e.toString()}'],
        'warnings': <String>[],
      };
    }
  }

  /// Mapeo de columnas por defecto (mantiene compatibilidad con formato original)
  static Map<String, int> _defaultColumnMapping() {
    return {
      'ID': 0,
      'Matrícula': 1,
      'Nombre': 2,
      'Género': 3,
      'Carrera': 4,
      'Generación': 5,
      'Grupo': 6,
      'Grupo Materia': 7,
      'Materia': 8,
      'Parcial 1': 9,
      'Parcial 2': 10,
      'Parcial 3': 11,
      'Parcial Final 1': 12,
      'Parcial Final 2': 13,
      'Parcial Final 3': 14,
      'Faltas P1': 15,
      'Faltas P2': 16,
      'Faltas P3': 17,
      'Profesor': 18,
      'Tutor': 19,
      'Tipo Curso': 20,
    };
  }
}
