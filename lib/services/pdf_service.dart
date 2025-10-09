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
      case 1: return alumno.faltasP1 ?? 0;
      case 2: return alumno.faltasP2 ?? 0;
      case 3: return alumno.faltasP3 ?? 0;
      default: return 0;
    }
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