import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';
import '../models/reporte.dart';

class PdfService {
  /// Genera un reporte PDF individual para un alumno
  static Future<Uint8List> generarReporteAlumno({
    required ReporteAlumno reporte,
    String? logoPath,
    String nombreInstitucion = 'Universidad Politécnica de Querétaro',
    bool incluirFirma = false,
    String textoFirma = '',
  }) async {
    final pdf = pw.Document();
    
    // Cargar fuente
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    
    // Cargar logo si existe
    pw.ImageProvider? logo;
    if (logoPath != null && File(logoPath).existsSync()) {
      try {
        final logoBytes = await File(logoPath).readAsBytes();
        logo = pw.MemoryImage(logoBytes);
      } catch (e) {
        // Ignorar errores de carga de logo
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              _buildHeader(
                nombreInstitucion: nombreInstitucion,
                logo: logo,
                font: font,
                fontBold: fontBold,
              ),
              
              pw.SizedBox(height: 20),
              
              // Título del reporte
              pw.Center(
                child: pw.Text(
                  'REPORTE INDIVIDUAL DE CALIFICACIONES',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Información del alumno
              _buildAlumnoInfo(reporte.alumno, font, fontBold),
              
              pw.SizedBox(height: 20),
              
              // Tabla de calificaciones
              _buildTablaCalificaciones(reporte, font, fontBold),
              
              pw.SizedBox(height: 20),
              
              // Resumen
              _buildResumenAlumno(reporte, font, fontBold),
              
              pw.Spacer(),
              
              // Pie de página
              _buildFooter(
                fechaGeneracion: reporte.fechaGeneracion,
                incluirFirma: incluirFirma,
                textoFirma: textoFirma,
                font: font,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Genera un reporte PDF para un grupo
  static Future<Uint8List> generarReporteGrupo({
    required ReporteGrupo reporte,
    String? logoPath,
    String nombreInstitucion = 'Universidad Politécnica de Querétaro',
    bool incluirFirma = false,
    String textoFirma = '',
  }) async {
    final pdf = pw.Document();
    
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    
    pw.ImageProvider? logo;
    if (logoPath != null && File(logoPath).existsSync()) {
      try {
        final logoBytes = await File(logoPath).readAsBytes();
        logo = pw.MemoryImage(logoBytes);
      } catch (e) {
        // Ignorar errores de carga de logo
      }
    }

    // Página 1: Resumen del grupo
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                nombreInstitucion: nombreInstitucion,
                logo: logo,
                font: font,
                fontBold: fontBold,
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Center(
                child: pw.Text(
                  'REPORTE DE GRUPO',
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              _buildGrupoInfo(reporte.grupo, font, fontBold),
              
              pw.SizedBox(height: 20),
              
              _buildEstadisticasGrupo(reporte, font, fontBold),
              
              pw.Spacer(),
              
              _buildFooter(
                fechaGeneracion: reporte.fechaGeneracion,
                incluirFirma: incluirFirma,
                textoFirma: textoFirma,
                font: font,
              ),
            ],
          );
        },
      ),
    );

    // Página 2: Lista de alumnos
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LISTA DE ALUMNOS',
                style: pw.TextStyle(font: fontBold, fontSize: 16),
              ),
              
              pw.SizedBox(height: 15),
              
              _buildTablaAlumnos(reporte.grupo.alumnosOrdenadosPorCalificacion, font, fontBold),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construye el encabezado del documento
  static pw.Widget _buildHeader({
    required String nombreInstitucion,
    pw.ImageProvider? logo,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (logo != null)
          pw.Image(logo, width: 60, height: 60),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                nombreInstitucion,
                style: pw.TextStyle(font: fontBold, fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Sistema de Gestión de Calificaciones',
                style: pw.TextStyle(font: font, fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        if (logo != null)
          pw.SizedBox(width: 60), // Espaciador para balance
      ],
    );
  }

  /// Construye la información del alumno
  static pw.Widget _buildAlumnoInfo(Alumno alumno, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMACIÓN DEL ESTUDIANTE', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Nombre: ${alumno.nombre}', style: pw.TextStyle(font: font)),
              ),
              pw.Expanded(
                child: pw.Text('Matrícula: ${alumno.matricula}', style: pw.TextStyle(font: font)),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Carrera: ${alumno.carrera}', style: pw.TextStyle(font: font)),
              ),
              pw.Expanded(
                child: pw.Text('Grupo: ${alumno.grupo}', style: pw.TextStyle(font: font)),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Materia: ${alumno.nombreMateria}', style: pw.TextStyle(font: font)),
              ),
              pw.Expanded(
                child: pw.Text('Profesor: ${alumno.nombreProfesor}', style: pw.TextStyle(font: font)),
              ),
            ],
          ),
          if (alumno.nombreTutor != null && alumno.nombreTutor!.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text('Tutor: ${alumno.nombreTutor}', style: pw.TextStyle(font: font)),
          ],
        ],
      ),
    );
  }

  /// Construye la tabla de calificaciones del alumno
  static pw.Widget _buildTablaCalificaciones(ReporteAlumno reporte, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Parcial', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Calif. Parcial', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Calif. Final', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Calif. Calculada', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Faltas', style: pw.TextStyle(font: fontBold)),
            ),
          ],
        ),
        // Datos
        for (int i = 1; i <= 3; i++)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('$i', style: pw.TextStyle(font: font)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(_formatCalificacion(_getParcialOriginal(reporte.alumno, i)), style: pw.TextStyle(font: font)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(_formatCalificacion(_getParcialFinal(reporte.alumno, i)), style: pw.TextStyle(font: font)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(_formatCalificacion(reporte.calificacionesParciales[i-1]), style: pw.TextStyle(font: font)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${_getFaltas(reporte.alumno, i)}', style: pw.TextStyle(font: font)),
              ),
            ],
          ),
      ],
    );
  }

  /// Construye el resumen del alumno
  static pw.Widget _buildResumenAlumno(ReporteAlumno reporte, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMEN', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Calificación Final: ${_formatCalificacion(reporte.calificacionFinal)}',
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Estado: ${reporte.estadoAcademico}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: reporte.aprueba ? PdfColors.green : PdfColors.red,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Total de Faltas: ${reporte.alumno.totalFaltas}', style: pw.TextStyle(font: font)),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Tipo de Curso: ${reporte.alumno.esRecursamiento ? "Recursamiento" : "Normal"}',
                  style: pw.TextStyle(font: font),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye la información del grupo
  static pw.Widget _buildGrupoInfo(Grupo grupo, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('INFORMACIÓN DEL GRUPO', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Grupo: ${grupo.nombre}', style: pw.TextStyle(font: font)),
              ),
              pw.Expanded(
                child: pw.Text('Materia: ${grupo.nombreMateria}', style: pw.TextStyle(font: font)),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text('Profesor: ${grupo.nombreProfesor}', style: pw.TextStyle(font: font)),
        ],
      ),
    );
  }

  /// Construye las estadísticas del grupo
  static pw.Widget _buildEstadisticasGrupo(ReporteGrupo reporte, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ESTADÍSTICAS DEL GRUPO', style: pw.TextStyle(font: fontBold, fontSize: 14)),
        pw.SizedBox(height: 10),
        
        // Estadísticas generales
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('Total de Alumnos: ${reporte.totalAlumnos}', style: pw.TextStyle(font: font)),
                  ),
                  pw.Expanded(
                    child: pw.Text('Promedio General: ${reporte.promedioGeneral.toStringAsFixed(2)}', style: pw.TextStyle(font: font)),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('Aprobados: ${reporte.aprobados} (${reporte.porcentajeAprobados.toStringAsFixed(1)}%)', style: pw.TextStyle(font: font)),
                  ),
                  pw.Expanded(
                    child: pw.Text('Reprobados: ${reporte.reprobados} (${reporte.porcentajeReprobados.toStringAsFixed(1)}%)', style: pw.TextStyle(font: font)),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('Sin Calificar: ${reporte.sinCalificar}', style: pw.TextStyle(font: font)),
                  ),
                  pw.Expanded(
                    child: pw.Text('Promedio de Faltas: ${reporte.promedioFaltas.toStringAsFixed(1)}', style: pw.TextStyle(font: font)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye la tabla de alumnos
  static pw.Widget _buildTablaAlumnos(List<Alumno> alumnos, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Nombre', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Matrícula', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Carrera', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Calificación', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Estado', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            ),
          ],
        ),
        // Datos
        for (final alumno in alumnos.take(30)) // Límite para evitar desbordamiento
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(alumno.nombre, style: pw.TextStyle(font: font, fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(alumno.matricula, style: pw.TextStyle(font: font, fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(alumno.carrera, style: pw.TextStyle(font: font, fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(_formatCalificacion(alumno.calcularCalificacionFinalCalculada()), style: pw.TextStyle(font: font, fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  alumno.estadoAcademico,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: alumno.aprueba() ? PdfColors.green : PdfColors.red,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Construye el pie de página
  static pw.Widget _buildFooter({
    required DateTime fechaGeneracion,
    bool incluirFirma = false,
    String textoFirma = '',
    required pw.Font font,
  }) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado el: ${_formatFecha(fechaGeneracion)}',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            if (incluirFirma && textoFirma.isNotEmpty)
              pw.Text(
                textoFirma,
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }

  // Métodos auxiliares
  static String _formatCalificacion(double? calificacion) {
    if (calificacion == null) return 'Sin calificar';
    return calificacion.toStringAsFixed(2);
  }

  static String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  static double? _getParcialOriginal(Alumno alumno, int numero) {
    switch (numero) {
      case 1: return alumno.parcial1;
      case 2: return alumno.parcial2;
      case 3: return alumno.parcial3;
      default: return null;
    }
  }

  static double? _getParcialFinal(Alumno alumno, int numero) {
    switch (numero) {
      case 1: return alumno.parcialFinal1;
      case 2: return alumno.parcialFinal2;
      case 3: return alumno.parcialFinal3;
      default: return null;
    }
  }

  static int _getFaltas(Alumno alumno, int numero) {
    switch (numero) {
      case 1: return alumno.faltasP1;
      case 2: return alumno.faltasP2;
      case 3: return alumno.faltasP3;
      default: return 0;
    }
  }

  /// Genera un reporte general institucional (multi-página)
  static Future<Uint8List> generarReporteGeneral({
    required List<Alumno> alumnos,
    required List<Grupo> grupos,
    required Map<String, Map<String, dynamic>> estadisticasPorCarrera,
    String? logoPath,
    String nombreInstitucion = 'Universidad Politécnica de Querétaro',
    bool incluirFirma = false,
    String textoFirma = '',
  }) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pw.ImageProvider? logo;
    if (logoPath != null && File(logoPath).existsSync()) {
      try {
        logo = pw.MemoryImage(await File(logoPath).readAsBytes());
      } catch (_) {}
    }

    // Compute global stats
    final Map<String, List<double>> calsPorMatricula = {};
    for (final a in alumnos) {
      final cal = a.calcularCalificacionFinalCalculada();
      if (cal != null) calsPorMatricula.putIfAbsent(a.matricula, () => []).add(cal);
    }
    final totalAlumnos = alumnos.map((a) => a.matricula).toSet().length;
    int aprobados = 0, reprobados = 0;
    double sumaPromedios = 0.0;
    for (final cals in calsPorMatricula.values) {
      final p = cals.reduce((a, b) => a + b) / cals.length;
      sumaPromedios += p;
      if (p >= 7.0) aprobados++; else reprobados++;
    }
    final promedioGeneral = calsPorMatricula.isEmpty ? 0.0 : sumaPromedios / calsPorMatricula.length;
    final sinCalificar = totalAlumnos - calsPorMatricula.length;
    final totalMaterias = alumnos.map((a) => a.nombreMateria).toSet().length;

    // Subject difficulty
    final Map<String, List<double>> calsPorMateria = {};
    for (final a in alumnos) {
      final cal = a.calcularCalificacionFinalCalculada();
      if (cal != null) calsPorMateria.putIfAbsent(a.nombreMateria, () => []).add(cal);
    }
    final materiasDif = calsPorMateria.entries.map((e) {
      final p = e.value.reduce((a, b) => a + b) / e.value.length;
      return <String, dynamic>{'materia': e.key, 'promedio': p, 'total': e.value.length};
    }).toList()
      ..sort((a, b) => (a['promedio'] as double).compareTo(b['promedio'] as double));

    // At-risk (deduplicated)
    final riesgo = alumnos.where((a) => a.estaEnRiesgo).map((a) => a.matricula).toSet().length;

    // Gender distribution (one record per student)
    final Map<String, String> generosPorMatricula = {};
    for (final a in alumnos) {
      generosPorMatricula[a.matricula] = a.genero;
    }
    final totalMujeres = generosPorMatricula.values.where((g) => g == 'F').length;
    final totalHombres = generosPorMatricula.values.where((g) => g == 'M').length;

    // Grade range distribution (per student average)
    final Map<String, int> distribucion = {
      '0-5': 0, '5-7': 0, '7-8': 0, '8-9': 0, '9-10': 0, 'S/C': 0,
    };
    for (final cals in calsPorMatricula.values) {
      final p = cals.reduce((a, b) => a + b) / cals.length;
      if (p < 5.0) distribucion['0-5'] = (distribucion['0-5'] ?? 0) + 1;
      else if (p < 7.0) distribucion['5-7'] = (distribucion['5-7'] ?? 0) + 1;
      else if (p < 8.0) distribucion['7-8'] = (distribucion['7-8'] ?? 0) + 1;
      else if (p < 9.0) distribucion['8-9'] = (distribucion['8-9'] ?? 0) + 1;
      else distribucion['9-10'] = (distribucion['9-10'] ?? 0) + 1;
    }
    distribucion['S/C'] = sinCalificar;

    // Generation breakdown
    final Map<String, Map<String, dynamic>> estadPorGen = {};
    for (final a in alumnos) {
      final gen = a.generacion ?? 'Sin generación';
      estadPorGen.putIfAbsent(gen, () => {'mats': <String>{}, 'cals': <double>[], 'riesgo': <String>{}});
      (estadPorGen[gen]!['mats'] as Set<String>).add(a.matricula);
      final cal = a.calcularCalificacionFinalCalculada();
      if (cal != null) (estadPorGen[gen]!['cals'] as List<double>).add(cal);
      if (a.estaEnRiesgo) (estadPorGen[gen]!['riesgo'] as Set<String>).add(a.matricula);
    }

    // At-risk students list (first record per matricula)
    final Map<String, Alumno> primeraPorMatricula = {};
    for (final a in alumnos) {
      primeraPorMatricula.putIfAbsent(a.matricula, () => a);
    }
    final atRiskMatriculas = alumnos.where((a) => a.estaEnRiesgo).map((a) => a.matricula).toSet();
    final atRiskAlumnos = atRiskMatriculas.map((m) => primeraPorMatricula[m]!).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(children: [
          _buildHeader(nombreInstitucion: nombreInstitucion, logo: logo, font: font, fontBold: fontBold),
          pw.SizedBox(height: 8),
          pw.Divider(),
        ]),
        footer: (ctx) => _buildFooter(fechaGeneracion: DateTime.now(), incluirFirma: incluirFirma, textoFirma: textoFirma, font: font),
        build: (ctx) => [
          pw.Center(child: pw.Text('REPORTE GENERAL INSTITUCIONAL', style: pw.TextStyle(font: fontBold, fontSize: 16))),
          pw.SizedBox(height: 16),

          // Global stats box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('ESTADÍSTICAS GENERALES', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Row(children: [
                pw.Expanded(child: pw.Text('Total alumnos únicos: $totalAlumnos', style: pw.TextStyle(font: font, fontSize: 10))),
                pw.Expanded(child: pw.Text('Total grupos: ${grupos.length}', style: pw.TextStyle(font: font, fontSize: 10))),
                pw.Expanded(child: pw.Text('Total materias: $totalMaterias', style: pw.TextStyle(font: font, fontSize: 10))),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Expanded(child: pw.Text('Promedio general: ${promedioGeneral.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                pw.Expanded(child: pw.Text('Aprobados: $aprobados (${totalAlumnos > 0 ? (aprobados / totalAlumnos * 100).toStringAsFixed(1) : 0}%)', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.green700))),
                pw.Expanded(child: pw.Text('Reprobados: $reprobados (${totalAlumnos > 0 ? (reprobados / totalAlumnos * 100).toStringAsFixed(1) : 0}%)', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.red))),
              ]),
              pw.SizedBox(height: 4),
              pw.Row(children: [
                pw.Expanded(child: pw.Text('Sin calificar: $sinCalificar', style: pw.TextStyle(font: font, fontSize: 10))),
                pw.Expanded(child: pw.Text('Alumnos en riesgo: $riesgo', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.orange700))),
                pw.Expanded(child: pw.Text('Mujeres: $totalMujeres  |  Hombres: $totalHombres', style: pw.TextStyle(font: font, fontSize: 10))),
              ]),
            ]),
          ),

          pw.SizedBox(height: 16),

          // Carrera table
          pw.Text('DESGLOSE POR CARRERA', style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.5),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.6),
              4: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Carrera', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Alumnos', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Promedio', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Aprobados', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Reprobados', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                ],
              ),
              ...estadisticasPorCarrera.entries.map((e) {
                final s = e.value;
                final pct = (s['porcentajeAprobados'] as double).toStringAsFixed(1);
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.key, style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${s['totalAlumnos']}', style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((s['promedio'] as double).toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${s['aprobados']} ($pct%)', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.green700))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${s['reprobados']}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.red))),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 16),

          // Subject difficulty table
          pw.Text('MATERIAS POR DIFICULTAD (promedio más bajo primero)', style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('#', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Materia', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Promedio', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Alumnos', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                ],
              ),
              ...materiasDif.take(20).toList().asMap().entries.map((e) {
                final m = e.value;
                final prom = m['promedio'] as double;
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${e.key + 1}', style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['materia'] as String, style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(prom.toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 8, color: prom < 7.0 ? PdfColors.red : PdfColors.green700))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${m['total']}', style: pw.TextStyle(font: font, fontSize: 8))),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 16),

          // Grade distribution table
          pw.Text('DISTRIBUCIÓN DE CALIFICACIONES (por alumno)', style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Rango', '0-5', '5-7', '7-8', '8-9', '9-10', 'S/C'].map((h) =>
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(font: fontBold, fontSize: 9)))).toList(),
              ),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Alumnos', style: pw.TextStyle(font: font, fontSize: 9))),
                ...['0-5', '5-7', '7-8', '8-9', '9-10', 'S/C'].map((r) {
                  final count = distribucion[r] ?? 0;
                  final pct = totalAlumnos > 0 ? (count / totalAlumnos * 100).toStringAsFixed(1) : '0.0';
                  final color = (r == '0-5' || r == '5-7') ? PdfColors.red : r == 'S/C' ? PdfColors.grey600 : PdfColors.green700;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('$count\n($pct%)', style: pw.TextStyle(font: font, fontSize: 8, color: color)),
                  );
                }),
              ]),
            ],
          ),

          if (estadPorGen.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('DESGLOSE POR GENERACIÓN', style: pw.TextStyle(font: fontBold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Generación', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Alumnos', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Promedio', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('En riesgo', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  ],
                ),
                ...estadPorGen.entries.map((e) {
                  final totalGen = (e.value['mats'] as Set<String>).length;
                  final calsGen = e.value['cals'] as List<double>;
                  final promGen = calsGen.isEmpty ? null : calsGen.reduce((a, b) => a + b) / calsGen.length;
                  final riesgoGen = (e.value['riesgo'] as Set<String>).length;
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.key, style: pw.TextStyle(font: font, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$totalGen', style: pw.TextStyle(font: font, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(promGen?.toStringAsFixed(2) ?? 'S/C', style: pw.TextStyle(font: font, fontSize: 8, color: (promGen ?? 0) >= 7.0 ? PdfColors.green700 : PdfColors.red))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$riesgoGen', style: pw.TextStyle(font: font, fontSize: 8, color: riesgoGen > 0 ? PdfColors.orange700 : PdfColors.black))),
                  ]);
                }),
              ],
            ),
          ],

          if (atRiskAlumnos.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('ALUMNOS EN RIESGO ACADÉMICO (${atRiskAlumnos.length})', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.orange700)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nombre', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Matrícula', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Carrera', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Grupo', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Faltas', style: pw.TextStyle(font: fontBold, fontSize: 9))),
                  ],
                ),
                ...atRiskAlumnos.take(30).map((a) => pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(a.nombre, style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(a.matricula, style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(a.carrera, style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(a.grupo, style: pw.TextStyle(font: font, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${a.totalFaltas}', style: pw.TextStyle(font: font, fontSize: 8, color: a.totalFaltas >= 2 ? PdfColors.orange700 : PdfColors.black))),
                ])),
              ],
            ),
            if (atRiskAlumnos.length > 30)
              pw.Text('... y ${atRiskAlumnos.length - 30} más', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Genera un reporte PDF completo para un alumno (todas sus materias en un solo PDF)
  static Future<Uint8List> generarReporteAlumnoCompleto({
    required List<Alumno> materias,
    String? logoPath,
    String nombreInstitucion = 'Universidad Politécnica de Querétaro',
    bool incluirFirma = false,
    String textoFirma = '',
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pw.ImageProvider? logo;
    if (logoPath != null && File(logoPath).existsSync()) {
      try {
        logo = pw.MemoryImage(await File(logoPath).readAsBytes());
      } catch (_) {}
    }

    final alumno = materias.first;

    // Aggregate stats
    final cals = materias
        .map((a) => a.calcularCalificacionFinalCalculada())
        .whereType<double>()
        .toList();
    final promedioGlobal =
        cals.isEmpty ? null : cals.reduce((a, b) => a + b) / cals.length;
    final aprobadas = cals.where((c) => c >= 7.0).length;
    final reprobadas = cals.where((c) => c < 7.0).length;
    final sinCalificar = materias.length - cals.length;
    final totalFaltas =
        materias.fold<int>(0, (s, a) => s + a.totalFaltas);
    final estaEnRiesgo = materias.any((a) => a.estaEnRiesgo);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => pw.Column(children: [
          _buildHeader(
              nombreInstitucion: nombreInstitucion,
              logo: logo,
              font: font,
              fontBold: fontBold),
          pw.SizedBox(height: 4),
          pw.Divider(),
        ]),
        footer: (ctx) => _buildFooter(
          fechaGeneracion: DateTime.now(),
          incluirFirma: incluirFirma,
          textoFirma: textoFirma,
          font: font,
        ),
        build: (ctx) => [
          pw.Center(
            child: pw.Text('REPORTE INDIVIDUAL DE CALIFICACIONES',
                style: pw.TextStyle(font: fontBold, fontSize: 15)),
          ),
          pw.SizedBox(height: 12),

          // Student data
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo700),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DATOS DEL ESTUDIANTE',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: PdfColors.indigo700)),
                  pw.SizedBox(height: 6),
                  pw.Row(children: [
                    pw.Expanded(
                        child: _infoRowPdf(
                            'Nombre', alumno.nombre, font, fontBold)),
                    pw.Expanded(
                        child: _infoRowPdf('Matrícula', alumno.matricula,
                            font, fontBold)),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Expanded(
                        child: _infoRowPdf(
                            'Carrera', alumno.carrera, font, fontBold)),
                    pw.Expanded(
                        child: _infoRowPdf(
                            'Grupo', alumno.grupo, font, fontBold)),
                  ]),
                  if (alumno.generacion != null ||
                      (alumno.nombreTutor != null &&
                          alumno.nombreTutor!.isNotEmpty)) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      if (alumno.generacion != null)
                        pw.Expanded(
                            child: _infoRowPdf('Generación',
                                alumno.generacion!, font, fontBold)),
                      if (alumno.nombreTutor != null &&
                          alumno.nombreTutor!.isNotEmpty)
                        pw.Expanded(
                            child: _infoRowPdf('Tutor',
                                alumno.nombreTutor!, font, fontBold)),
                    ]),
                  ],
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Expanded(
                        child: _infoRowPdf(
                            'Género',
                            alumno.genero == 'F'
                                ? 'Femenino'
                                : alumno.genero == 'M'
                                    ? 'Masculino'
                                    : alumno.genero,
                            font,
                            fontBold)),
                    pw.Expanded(
                        child: _infoRowPdf(
                            'Tipo de Curso',
                            alumno.esRecursamiento
                                ? 'Recursamiento'
                                : 'Normal',
                            font,
                            fontBold)),
                  ]),
                ]),
          ),

          pw.SizedBox(height: 10),

          // Summary stats
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: estaEnRiesgo ? PdfColors.orange50 : PdfColors.green50,
              border: pw.Border.all(
                  color:
                      estaEnRiesgo ? PdfColors.orange : PdfColors.green700),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RESUMEN ACADÉMICO',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: estaEnRiesgo
                              ? PdfColors.orange700
                              : PdfColors.green700)),
                  pw.SizedBox(height: 8),
                  pw.Row(children: [
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.center,
                            children: [
                          pw.Text(
                              promedioGlobal?.toStringAsFixed(2) ?? 'S/C',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  color: (promedioGlobal ?? 0) >= 7.0
                                      ? PdfColors.green700
                                      : PdfColors.red)),
                          pw.Text('Promedio Global',
                              style: pw.TextStyle(
                                  font: font, fontSize: 8)),
                        ])),
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.center,
                            children: [
                          pw.Text('$aprobadas',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  color: PdfColors.green700)),
                          pw.Text('Materias Aprobadas',
                              style:
                                  pw.TextStyle(font: font, fontSize: 8)),
                        ])),
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.center,
                            children: [
                          pw.Text('$reprobadas',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  color: PdfColors.red)),
                          pw.Text('Materias Reprobadas',
                              style:
                                  pw.TextStyle(font: font, fontSize: 8)),
                        ])),
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.center,
                            children: [
                          pw.Text('$totalFaltas',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  color: totalFaltas >= 4
                                      ? PdfColors.red
                                      : PdfColors.grey800)),
                          pw.Text('Total Faltas',
                              style:
                                  pw.TextStyle(font: font, fontSize: 8)),
                        ])),
                    if (sinCalificar > 0)
                      pw.Expanded(
                          child: pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.center,
                              children: [
                            pw.Text('$sinCalificar',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 22,
                                    color: PdfColors.grey600)),
                            pw.Text('Sin Calificar',
                                style: pw.TextStyle(
                                    font: font, fontSize: 8)),
                          ])),
                  ]),
                  if (estaEnRiesgo) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('! ALUMNO EN RIESGO ACADEMICO',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: PdfColors.orange700)),
                  ],
                ]),
          ),

          pw.SizedBox(height: 12),

          // Subject table
          pw.Text('CALIFICACIONES POR MATERIA',
              style: pw.TextStyle(font: fontBold, fontSize: 11)),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.2),
              1: const pw.FlexColumnWidth(0.9),
              2: const pw.FlexColumnWidth(0.9),
              3: const pw.FlexColumnWidth(0.9),
              4: const pw.FlexColumnWidth(0.9),
              5: const pw.FlexColumnWidth(0.9),
              6: const pw.FlexColumnWidth(0.9),
              7: const pw.FlexColumnWidth(1.2),
              8: const pw.FlexColumnWidth(0.8),
              9: const pw.FlexColumnWidth(1.3),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.indigo700),
                children: [
                  _thCell('Materia', fontBold, PdfColors.white),
                  _thCell('P1', fontBold, PdfColors.white),
                  _thCell('F1', fontBold, PdfColors.white),
                  _thCell('P2', fontBold, PdfColors.white),
                  _thCell('F2', fontBold, PdfColors.white),
                  _thCell('P3', fontBold, PdfColors.white),
                  _thCell('F3', fontBold, PdfColors.white),
                  _thCell('Calc.Final', fontBold, PdfColors.white),
                  _thCell('Faltas', fontBold, PdfColors.white),
                  _thCell('Estado', fontBold, PdfColors.white),
                ],
              ),
              ...materias.map((m) {
                final cal = m.calcularCalificacionFinalCalculada();
                final ap = cal != null && cal >= 7.0;
                final rowColor = cal == null
                    ? PdfColors.grey100
                    : ap
                        ? PdfColors.white
                        : PdfColors.red50;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _tdCell(m.nombreMateria, font),
                    _tdCell(_fmtD(m.parcial1), font),
                    _tdCell(_fmtD(m.parcialFinal1), font),
                    _tdCell(_fmtD(m.parcial2), font),
                    _tdCell(_fmtD(m.parcialFinal2), font),
                    _tdCell(_fmtD(m.parcial3), font),
                    _tdCell(_fmtD(m.parcialFinal3), font),
                    _tdCell(
                      cal?.toStringAsFixed(2) ?? 'S/C',
                      fontBold,
                      color: cal == null
                          ? PdfColors.grey
                          : ap
                              ? PdfColors.green700
                              : PdfColors.red,
                    ),
                    _tdCell(
                      '${m.totalFaltas}',
                      font,
                      color: m.totalFaltas >= 3
                          ? PdfColors.red
                          : PdfColors.black,
                    ),
                    _tdCell(
                      cal == null
                          ? 'S/C'
                          : ap
                              ? 'Aprobado'
                              : 'Reprobado',
                      font,
                      color: cal == null
                          ? PdfColors.grey600
                          : ap
                              ? PdfColors.green700
                              : PdfColors.red,
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'P1/P2/P3 = Calificación del parcial  •  F1/F2/F3 = Calificación final del parcial  •  Calc.Final = Promedio calculado de los tres parciales.',
            style:
                pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static pw.Widget _thCell(String text, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 8, color: color)),
    );
  }

  static pw.Widget _tdCell(String text, pw.Font font, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font, fontSize: 8, color: color ?? PdfColors.black)),
    );
  }

  static pw.Widget _infoRowPdf(
      String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(font: fontBold, fontSize: 9)),
        pw.TextSpan(
            text: value, style: pw.TextStyle(font: font, fontSize: 9)),
      ]),
    );
  }

  static String _fmtD(double? val) {
    if (val == null) return '-';
    return val.toStringAsFixed(1);
  }

  /// Guarda un PDF en el directorio de documentos
  static Future<String> guardarPdf(Uint8List pdfBytes, String nombreArchivo) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$nombreArchivo';
    final file = File(path);
    await file.writeAsBytes(pdfBytes);
    return path;
  }

  /// Imprime un PDF
  static Future<void> imprimirPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}