import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';

class ExcelExportService {
  /// Exporta todos los alumnos con calificaciones calculadas a un archivo Excel
  static Future<String?> exportarAlumnos({
    required List<Alumno> alumnos,
    required String nombreArchivo,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Calificaciones'];
      excel.setDefaultSheet('Calificaciones');

      // Encabezados
      final headers = [
        'Matrícula', 'Nombre', 'Género', 'Carrera', 'Generación', 'Grupo',
        'Materia', 'Profesor',
        'P1', 'PF1', 'Cal P1',
        'P2', 'PF2', 'Cal P2',
        'P3', 'PF3', 'Cal P3',
        'Cal Final', 'Total Faltas', 'Estado', '¿En riesgo?', 'Rango',
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      // Datos
      for (int r = 0; r < alumnos.length; r++) {
        final a = alumnos[r];
        final rowIndex = r + 1;
        final calFinal = a.calcularCalificacionFinalCalculada();

        final values = [
          a.matricula,
          a.nombre,
          a.genero == 'M' ? 'Masculino' : 'Femenino',
          a.carrera,
          a.generacion ?? '',
          a.grupo,
          a.nombreMateria,
          a.nombreProfesor,
          a.parcial1?.toString() ?? '',
          a.parcialFinal1?.toString() ?? '',
          a.calcularCalificacionParcial(1)?.toStringAsFixed(2) ?? '',
          a.parcial2?.toString() ?? '',
          a.parcialFinal2?.toString() ?? '',
          a.calcularCalificacionParcial(2)?.toStringAsFixed(2) ?? '',
          a.parcial3?.toString() ?? '',
          a.parcialFinal3?.toString() ?? '',
          a.calcularCalificacionParcial(3)?.toStringAsFixed(2) ?? '',
          calFinal?.toStringAsFixed(2) ?? 'S/C',
          a.totalFaltas.toString(),
          a.estadoAcademico,
          a.estaEnRiesgo ? 'Sí' : 'No',
          a.rangoCalificacion,
        ];

        for (int c = 0; c < values.length; c++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex))
              .value = TextCellValue(values[c]);
        }
      }

      return await _guardar(excel, nombreArchivo);
    } catch (_) {
      return null;
    }
  }

  /// Exporta resumen estadístico por grupo
  static Future<String?> exportarResumenGrupos({
    required List<Grupo> grupos,
    required String nombreArchivo,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Resumen'];
      excel.setDefaultSheet('Resumen');

      final headers = [
        'Grupo', 'Materia', 'Profesor',
        'Total Alumnos', 'Aprobados', 'Reprobados', 'Sin Calificar',
        '% Aprobados', 'Promedio General',
        '% Reprobación P1', '% Reprobación P2', '% Reprobación P3',
        'Alumnos en Riesgo', 'Necesitan Extraordinario',
        'Correlación Faltas-Cal', 'Parcial Más Difícil',
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(bold: true);
      }

      for (int r = 0; r < grupos.length; r++) {
        final g = grupos[r];
        final tasas = g.tasaReprobacionPorParcial;
        final rowIndex = r + 1;

        final values = [
          g.nombre,
          g.materia,
          g.profesor,
          g.totalAlumnos.toString(),
          g.aprobados().toString(),
          g.reprobados().toString(),
          g.sinCalificar().toString(),
          '${g.porcentajeAprobados().toStringAsFixed(1)}%',
          g.promedioGeneral.toStringAsFixed(2),
          '${(tasas[1] ?? 0).toStringAsFixed(1)}%',
          '${(tasas[2] ?? 0).toStringAsFixed(1)}%',
          '${(tasas[3] ?? 0).toStringAsFixed(1)}%',
          g.alumnosEnRiesgo.length.toString(),
          g.alumnosNecesitanExtraordinario.length.toString(),
          g.correlacionFaltasCalificacion.toStringAsFixed(3),
          'P${g.parcialMasDificil}',
        ];

        for (int c = 0; c < values.length; c++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex))
              .value = TextCellValue(values[c]);
        }
      }

      return await _guardar(excel, nombreArchivo);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _guardar(Excel excel, String nombreArchivo) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$nombreArchivo.xlsx';
    final bytes = excel.save();
    if (bytes == null) return null;
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
