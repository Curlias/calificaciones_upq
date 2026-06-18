import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';

class StorageService {
  static const String _reportsKey = 'saved_reports';

  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  static Future<bool> saveReport({
    required String reportId,
    required String reportName,
    required List<Alumno> alumnos,
    required List<Grupo> grupos,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dir = await getAppDocumentsDirectory();

      final reportsDir = Directory('${dir.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final reportFile = File('${reportsDir.path}/$reportId.json');
      final data = {
        'id': reportId,
        'name': reportName,
        'createdAt': DateTime.now().toIso8601String(),
        'alumnos': alumnos.map((a) => {
          'id': a.id,
          'matricula': a.matricula,
          'nombre': a.nombre,
          'genero': a.genero,
          'carrera': a.carrera,
          'generacion': a.generacion,         // BUG FIX: campo faltante
          'grupo': a.grupo,
          'grupoMateria': a.grupoMateria,
          'nombreMateria': a.nombreMateria,
          'nombreProfesor': a.nombreProfesor,
          'nombreTutor': a.nombreTutor,
          'parcial1': a.parcial1,
          'parcial2': a.parcial2,
          'parcial3': a.parcial3,
          'parcialFinal1': a.parcialFinal1,
          'parcialFinal2': a.parcialFinal2,
          'parcialFinal3': a.parcialFinal3,
          'faltasP1': a.faltasP1,
          'faltasP2': a.faltasP2,
          'faltasP3': a.faltasP3,
          'esRecursamiento': a.esRecursamiento,
        }).toList(),
      };

      await reportFile.writeAsString(json.encode(data));

      final reports = await getSavedReports();
      reports[reportId] = {
        'name': reportName,
        'createdAt': DateTime.now().toIso8601String(),
        'alumnosCount': alumnos.length,
        'gruposCount': grupos.length,
      };

      await prefs.setString(_reportsKey, json.encode(reports));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getSavedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_reportsKey);
      if (reportsJson == null) return {};
      return Map<String, dynamic>.from(json.decode(reportsJson));
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>?> loadReport(String reportId) async {
    try {
      final dir = await getAppDocumentsDirectory();
      final reportFile = File('${dir.path}/reports/$reportId.json');
      if (!await reportFile.exists()) return null;
      final content = await reportFile.readAsString();
      return json.decode(content);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> renameReport(String reportId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = await getSavedReports();
      if (!reports.containsKey(reportId)) return false;
      reports[reportId]['name'] = newName;
      await prefs.setString(_reportsKey, json.encode(reports));

      final reportData = await loadReport(reportId);
      if (reportData != null) {
        reportData['name'] = newName;
        final dir = await getAppDocumentsDirectory();
        final reportFile = File('${dir.path}/reports/$reportId.json');
        await reportFile.writeAsString(json.encode(reportData));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = await getSavedReports();
      reports.remove(reportId);
      await prefs.setString(_reportsKey, json.encode(reports));

      final dir = await getAppDocumentsDirectory();
      final reportFile = File('${dir.path}/reports/$reportId.json');
      if (await reportFile.exists()) await reportFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<Alumno> parseAlumnos(List<dynamic> alumnosData) {
    return alumnosData.map((data) => Alumno(
      id: data['id'] ?? '',
      matricula: data['matricula'] ?? '',
      nombre: data['nombre'] ?? '',
      genero: data['genero'] ?? '',
      carrera: data['carrera'] ?? '',
      generacion: data['generacion'],           // BUG FIX: deserializar generacion
      grupo: data['grupo'] ?? '',
      grupoMateria: data['grupoMateria'],
      nombreMateria: data['nombreMateria'] ?? '',
      nombreProfesor: data['nombreProfesor'] ?? '',
      nombreTutor: data['nombreTutor'],
      parcial1: (data['parcial1'] as num?)?.toDouble(),
      parcial2: (data['parcial2'] as num?)?.toDouble(),
      parcial3: (data['parcial3'] as num?)?.toDouble(),
      parcialFinal1: (data['parcialFinal1'] as num?)?.toDouble(),
      parcialFinal2: (data['parcialFinal2'] as num?)?.toDouble(),
      parcialFinal3: (data['parcialFinal3'] as num?)?.toDouble(),
      faltasP1: data['faltasP1'] ?? 0,
      faltasP2: data['faltasP2'] ?? 0,
      faltasP3: data['faltasP3'] ?? 0,
      esRecursamiento: data['esRecursamiento'] ?? false,
    )).toList();
  }
}
