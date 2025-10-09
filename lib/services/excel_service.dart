import 'dart:io';
import 'package:excel/excel.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';

class ExcelService {
  static const String _hojaGruposOfi = 'GruposOfi';

  /// Parsea un archivo Excel y convierte los datos en listas de alumnos y grupos
  static Future<Map<String, dynamic>> parseExcelFile(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      // Verificar que existe la hoja GruposOfi
      if (!excel.tables.containsKey(_hojaGruposOfi)) {
        throw Exception('No se encontró la hoja "$_hojaGruposOfi" en el archivo Excel');
      }

      final sheet = excel.tables[_hojaGruposOfi]!;
      final alumnos = await _parseAlumnos(sheet);
      final grupos = _organizarPorGrupos(alumnos);

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
  static Future<List<Alumno>> _parseAlumnos(Sheet sheet) async {
    final List<Alumno> alumnos = [];
    final rows = sheet.rows;
    
    if (rows.length < 2) {
      throw Exception('El archivo no contiene datos válidos');
    }

    // Empezar desde la fila 2 (índice 1), asumiendo que la fila 1 son headers
    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        
        // Obtener valores de las celdas (índice 0-based)
        final id = _getCellValue(row, 0) ?? '';
        final matricula = _getCellValue(row, 1) ?? '';
        final nombre = _getCellValue(row, 2) ?? '';
        final genero = _getCellValue(row, 3) ?? '';
        final carrera = _getCellValue(row, 4) ?? '';
        final grupo = _getCellValue(row, 5) ?? '';
        final nombreMateria = _getCellValue(row, 6) ?? '';
        
        // Parciales
        final parcial1 = _parseDouble(_getCellValue(row, 7));
        final parcial2 = _parseDouble(_getCellValue(row, 8));
        final parcial3 = _parseDouble(_getCellValue(row, 9));
        
        // Parciales finales
        final parcialFinal1 = _parseDouble(_getCellValue(row, 10));
        final parcialFinal2 = _parseDouble(_getCellValue(row, 11));
        final parcialFinal3 = _parseDouble(_getCellValue(row, 12));
        
        // Faltas
        final faltasP1 = _parseInt(_getCellValue(row, 13));
        final faltasP2 = _parseInt(_getCellValue(row, 14));
        final faltasP3 = _parseInt(_getCellValue(row, 15));
        
        // Otros datos
        final nombreProfesor = _getCellValue(row, 16) ?? '';
        final nombreTutor = _getCellValue(row, 17);
        final tipoCurso = _getCellValue(row, 18) ?? 'N';
        
        final alumno = Alumno(
          id: id,
          matricula: matricula,
          nombre: nombre,
          genero: genero,
          carrera: carrera,
          grupo: grupo,
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
  static List<Grupo> _organizarPorGrupos(List<Alumno> alumnos) {
    final Map<String, List<Alumno>> gruposMap = {};
    
    for (final alumno in alumnos) {
      final key = '${alumno.grupo}_${alumno.nombreMateria}';
      if (!gruposMap.containsKey(key)) {
        gruposMap[key] = [];
      }
      gruposMap[key]!.add(alumno);
    }
    
    return gruposMap.entries.map((entry) {
      final alumnos = entry.value;
      return Grupo(
        nombre: alumnos.first.grupo,
        materia: alumnos.first.nombreMateria,
        alumnos: alumnos,
        profesor: alumnos.first.nombreProfesor,
        carrera: alumnos.first.carrera,
      );
    }).toList();
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

  /// Valida la estructura del archivo Excel
  static Future<Map<String, dynamic>> validateExcelStructure(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final errors = <String>[];
      final warnings = <String>[];

      // Verificar que existe la hoja GruposOfi
      if (!excel.tables.containsKey(_hojaGruposOfi)) {
        errors.add('No se encontró la hoja "$_hojaGruposOfi"');
      } else {
        final sheet = excel.tables[_hojaGruposOfi]!;
        final rows = sheet.rows;

        // Verificar que tiene al menos 2 filas (header + data)
        if (rows.length < 2) {
          errors.add('La hoja "$_hojaGruposOfi" no contiene datos');
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
}
