import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alumno.dart';
import '../models/grupo.dart';

class StorageService {
  static const String _reportsKey = 'saved_reports';

  /// Obtiene el directorio de documentos de la aplicación
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Guarda un informe con sus datos
  static Future<bool> saveReport({
    required String reportId,
    required String reportName,
    required List<Alumno> alumnos,
    required List<Grupo> grupos,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dir = await getAppDocumentsDirectory();
      
      // Crear directorio para los informes si no existe
      final reportsDir = Directory('${dir.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      // Guardar datos del informe en archivo JSON
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

      // Guardar referencia en SharedPreferences
      final reports = await getSavedReports();
      reports[reportId] = {
        'name': reportName,
        'createdAt': DateTime.now().toIso8601String(),
        'alumnosCount': alumnos.length,
        'gruposCount': grupos.length,
      };
      
      await prefs.setString(_reportsKey, json.encode(reports));
      return true;
    } catch (e) {
      print('Error saving report: $e');
      return false;
    }
  }

  /// Obtiene la lista de informes guardados
  static Future<Map<String, dynamic>> getSavedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_reportsKey);
      if (reportsJson == null) return {};
      return Map<String, dynamic>.from(json.decode(reportsJson));
    } catch (e) {
      print('Error getting saved reports: $e');
      return {};
    }
  }

  /// Carga un informe específico
  static Future<Map<String, dynamic>?> loadReport(String reportId) async {
    try {
      final dir = await getAppDocumentsDirectory();
      final reportFile = File('${dir.path}/reports/$reportId.json');
      
      if (!await reportFile.exists()) return null;
      
      final content = await reportFile.readAsString();
      return json.decode(content);
    } catch (e) {
      print('Error loading report: $e');
      return null;
    }
  }

  /// Renombra un informe
  static Future<bool> renameReport(String reportId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = await getSavedReports();
      
      if (!reports.containsKey(reportId)) return false;
      
      reports[reportId]['name'] = newName;
      await prefs.setString(_reportsKey, json.encode(reports));
      
      // Actualizar el nombre en el archivo JSON también
      final reportData = await loadReport(reportId);
      if (reportData != null) {
        reportData['name'] = newName;
        final dir = await getAppDocumentsDirectory();
        final reportFile = File('${dir.path}/reports/$reportId.json');
        await reportFile.writeAsString(json.encode(reportData));
      }
      
      return true;
    } catch (e) {
      print('Error renaming report: $e');
      return false;
    }
  }

  /// Elimina un informe
  static Future<bool> deleteReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reports = await getSavedReports();
      
      reports.remove(reportId);
      await prefs.setString(_reportsKey, json.encode(reports));
      
      // Eliminar archivo
      final dir = await getAppDocumentsDirectory();
      final reportFile = File('${dir.path}/reports/$reportId.json');
      if (await reportFile.exists()) {
        await reportFile.delete();
      }
      
      return true;
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }

  /// Convierte datos JSON a lista de Alumnos
  static List<Alumno> parseAlumnos(List<dynamic> alumnosData) {
    return alumnosData.map((data) => Alumno(
      id: data['id'],
      matricula: data['matricula'],
      nombre: data['nombre'],
      genero: data['genero'],
      carrera: data['carrera'],
      grupo: data['grupo'],
      grupoMateria: data['grupoMateria'],
      nombreMateria: data['nombreMateria'],
      nombreProfesor: data['nombreProfesor'],
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
