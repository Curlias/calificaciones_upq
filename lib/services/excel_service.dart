import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:excel2003/excel2003.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';

class ExcelService {
  static const String _hojaGruposOfi = 'GruposOfi';

  /// Parsea un archivo Excel (.xlsx o .xls) y devuelve alumnos y grupos.
  static Future<Map<String, dynamic>> parseExcelFile(
    String filePath, {
    String? sheetName,
    Map<String, int>? columnMapping,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final extension = filePath.split('.').last.toLowerCase();

      // Convertir a una lista uniforme de filas (List<List<dynamic>>)
      // Estrategia: intentar el parser correspondiente a la extensión primero;
      // si falla (e.g. .xls con contenido OOXML), intentar el otro parser.
      final List<List<dynamic>> rawRows = _leerFilas(
        bytes,
        extension: extension,
        sheetName: sheetName,
      );

      final alumnos = _parseAlumnos(rawRows, columnMapping: columnMapping);
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

  /// Convierte filas dinámicas en objetos Alumno.
  static List<Alumno> _parseAlumnos(
    List<List<dynamic>> rows, {
    Map<String, int>? columnMapping,
  }) {
    final List<Alumno> alumnos = [];
    final mapping = columnMapping ?? _defaultColumnMapping();

    if (rows.length < 2) {
      throw Exception('El archivo no contiene datos válidos');
    }

    // Fila 0 = encabezados, datos desde fila 1
    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];

        final id = _val(row, mapping['ID']!) ?? '';
        final matricula = _val(row, mapping['Matrícula']!) ?? '';
        final nombre = _val(row, mapping['Nombre']!) ?? '';

        // Saltar filas completamente vacías
        if (matricula.isEmpty && nombre.isEmpty) continue;

        final genero = _normalizarGenero(_val(row, mapping['Género']!) ?? '');
        final carrera = _val(row, mapping['Carrera']!) ?? '';
        final generacion = mapping.containsKey('Generación')
            ? _val(row, mapping['Generación']!)
            : null;
        final grupo = _val(row, mapping['Grupo']!) ?? '';
        final grupoMateria = mapping.containsKey('Grupo Materia')
            ? _val(row, mapping['Grupo Materia']!)
            : null;
        final nombreMateria = _val(row, mapping['Materia']!) ?? '';

        final parcial1 = _dbl(_val(row, mapping['Parcial 1']!));
        final parcial2 = _dbl(_val(row, mapping['Parcial 2']!));
        final parcial3 = _dbl(_val(row, mapping['Parcial 3']!));
        final parcialFinal1 = _dbl(_val(row, mapping['Parcial Final 1']!));
        final parcialFinal2 = _dbl(_val(row, mapping['Parcial Final 2']!));
        final parcialFinal3 = _dbl(_val(row, mapping['Parcial Final 3']!));
        final faltasP1 = _int(_val(row, mapping['Faltas P1']!));
        final faltasP2 = _int(_val(row, mapping['Faltas P2']!));
        final faltasP3 = _int(_val(row, mapping['Faltas P3']!));
        final nombreProfesor = _val(row, mapping['Profesor']!) ?? '';
        final nombreTutor = _val(row, mapping['Tutor']!);
        final tipoCurso = _val(row, mapping['Tipo Curso']!) ?? 'N';

        alumnos.add(Alumno(
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
        ));
      } catch (_) {
        continue;
      }
    }

    return alumnos;
  }

  /// Organiza los alumnos por grupos.
  static List<Grupo> organizarPorGrupos(List<Alumno> alumnos) {
    final Map<String, List<Alumno>> gruposMap = {};

    for (final alumno in alumnos) {
      gruposMap.putIfAbsent(alumno.grupo, () => []).add(alumno);
    }

    return gruposMap.entries.map((entry) {
      final alumnosGrupo = entry.value;
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

  /// Valida la estructura del archivo (solo XLSX; XLS siempre pasa).
  static Future<Map<String, dynamic>> validateExcelStructure(
    String filePath, {
    String? sheetName,
  }) async {
    final extension = filePath.split('.').last.toLowerCase();

    // XLS: no podemos inspeccionar headers sin parsear, así que lo dejamos pasar
    if (extension == 'xls') {
      return {'isValid': true, 'errors': <String>[], 'warnings': <String>[]};
    }

    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final errors = <String>[];
      final warnings = <String>[];

      if (excel.tables.isEmpty) {
        errors.add('El archivo no contiene hojas de cálculo válidas');
        return {'isValid': false, 'errors': errors, 'warnings': warnings};
      }

      final targetSheet = sheetName ?? _hojaGruposOfi;
      final sheetToUse = excel.tables.containsKey(targetSheet)
          ? targetSheet
          : excel.tables.keys.first;

      final sheet = excel.tables[sheetToUse]!;
      final rows = sheet.rows;

      if (rows.length < 2) {
        errors.add('La hoja "$sheetToUse" no contiene datos suficientes (mínimo 2 filas)');
      } else {
        final headerRow = rows[0];
        final requiredColumns = [
          'ID', 'Matricula', 'Alumno', 'Genero', 'Carrera', 'Grupo',
          'Nombre de la Materia', 'Parcial 1', 'Parcial 2', 'Parcial 3',
        ];
        for (int i = 0; i < requiredColumns.length && i < headerRow.length; i++) {
          final cellValue = headerRow[i]?.value?.toString();
          if (cellValue == null ||
              !cellValue.contains(requiredColumns[i].split(' ')[0])) {
            warnings.add('Columna ${i + 1}: Se esperaba "${requiredColumns[i]}"');
          }
        }
        if (rows.length > 1000) {
          warnings.add('El archivo contiene ${rows.length - 1} filas. El procesamiento puede tardar.');
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

  // ── Parseo de filas con fallback automático ───────────────────────────────

  /// Lee las filas del archivo usando el parser correcto.
  /// Si el parser primario falla (p.ej. .xls con contenido OOXML) intenta el otro.
  static List<List<dynamic>> _leerFilas(
    Uint8List bytes, {
    required String extension,
    String? sheetName,
  }) {
    List<List<dynamic>> tryOoxml() {
      final excel = Excel.decodeBytes(bytes);
      final targetName = sheetName ?? _hojaGruposOfi;
      final sheetToUse = excel.tables.containsKey(targetName)
          ? targetName
          : excel.tables.keys.first;
      final sheet = excel.tables[sheetToUse]!;
      return sheet.rows
          .map((row) => row.map<dynamic>((cell) => cell?.value).toList())
          .toList();
    }

    List<List<dynamic>> tryBiff8() {
      final reader = XlsReader.fromBytes(bytes);
      if (reader.sheetCount == 0) throw Exception('Sin hojas en el archivo XLS');
      final nameToFind = sheetName ?? _hojaGruposOfi;
      final xlsSheet = reader.sheetByName(nameToFind) ?? reader.sheet(0);
      return xlsSheet.rows;
    }

    if (extension == 'xls') {
      // .xls → intentar BIFF8 primero; si falla el archivo tiene contenido OOXML
      try {
        return tryBiff8();
      } catch (_) {
        return tryOoxml();
      }
    } else {
      // .xlsx → intentar OOXML primero; fallback a BIFF8 por si acaso
      try {
        return tryOoxml();
      } catch (_) {
        return tryBiff8();
      }
    }
  }

  // ── Utilidades privadas ────────────────────────────────────────────────────

  /// Extrae un valor de una fila dinámica como String, o null.
  /// Convierte doubles enteros (ej: 123045385.0) a entero para evitar el sufijo ".0".
  static String? _val(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final v = row[index];
    if (v == null) return null;
    if (v is double && v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toString().trim();
  }

  static double? _dbl(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  static int _int(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }

  /// Normaliza género a 'M' o 'F'. Verifica femenino primero.
  static String _normalizarGenero(String genero) {
    final g = genero.toLowerCase().trim();
    if (g == 'f' || g == 'femenino' || g == 'mujer' || g == 'female' || g == 'woman') {
      return 'F';
    }
    if (g == 'm' || g == 'masculino' || g == 'hombre' || g == 'h' || g == 'male' || g == 'man') {
      return 'M';
    }
    return genero.toUpperCase();
  }

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
