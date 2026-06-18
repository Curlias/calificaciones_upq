import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:excel2003/excel2003.dart';
import 'dart:io';
import 'dart:typed_data';
import 'import_screen.dart';

class ImportConfigScreen extends StatefulWidget {
  final String filePath;

  const ImportConfigScreen({
    super.key,
    required this.filePath,
  });

  @override
  State<ImportConfigScreen> createState() => _ImportConfigScreenState();
}

class _ImportConfigScreenState extends State<ImportConfigScreen> {
  Excel? _excel;
  List<String> _sheetNames = [];
  String? _selectedSheet;
  Map<String, List<String>> _sheetHeaders = {};
  Map<String, int> _columnMapping = {};
  bool _isLoading = true;
  String? _error;

  final List<String> _requiredFields = [
    'ID',
    'Matrícula',
    'Nombre',
    'Género',
    'Carrera',
    'Generación',
    'Grupo',
    'Grupo Materia',
    'Materia',
    'Parcial 1',
    'Parcial 2',
    'Parcial 3',
    'Parcial Final 1',
    'Parcial Final 2',
    'Parcial Final 3',
    'Faltas P1',
    'Faltas P2',
    'Faltas P3',
    'Profesor',
    'Tutor',
    'Tipo Curso',
  ];

  @override
  void initState() {
    super.initState();
    _loadExcelFile();
  }

  Future<void> _loadExcelFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final bytes = await File(widget.filePath).readAsBytes();
      final extension = widget.filePath.split('.').last.toLowerCase();

      // Detectar formato con fallback automático:
      // .xls puede contener OOXML (renombrado), .xlsx puede ser BIFF8 (raro).
      bool loadedAsOoxml = false;

      if (extension == 'xls') {
        // Intentar BIFF8 primero; si falla intentar OOXML
        try {
          _loadFromBiff8(bytes);
        } catch (_) {
          _excel = Excel.decodeBytes(bytes);
          loadedAsOoxml = true;
        }
      } else {
        // Intentar OOXML primero; fallback a BIFF8
        try {
          _excel = Excel.decodeBytes(bytes);
          loadedAsOoxml = true;
        } catch (_) {
          _loadFromBiff8(bytes);
        }
      }

      if (loadedAsOoxml && _excel != null) {
        _sheetNames = _excel!.tables.keys.toList();
        for (final sheetName in _sheetNames) {
          final sheet = _excel!.tables[sheetName]!;
          if (sheet.rows.isNotEmpty) {
            _sheetHeaders[sheetName] = sheet.rows[0]
                .map((cell) => cell?.value?.toString() ?? '')
                .toList();
          }
        }
      }

      if (_sheetNames.isNotEmpty) {
        _selectedSheet = _sheetNames[0];
        _autoMapColumns();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el archivo: $e';
        _isLoading = false;
      });
    }
  }

  void _autoMapColumns() {
    if (_selectedSheet == null) return;

    final headers = _sheetHeaders[_selectedSheet!] ?? [];
    _columnMapping.clear();

    // Mapeo en orden de prioridad: primero las más específicas
    final mappings = {
      // Primero: Faltas (más específicas)
      'Faltas P1': ['faltas p1', 'faltas del parcial 1', 'falta parcial 1', 'faltas parc 1', 'faltas parc. 1', 'inasistencias p1', 'faltasp1', 'falta p1', 'inasistencias 1'],
      'Faltas P2': ['faltas p2', 'faltas del parcial 2', 'falta parcial 2', 'faltas parc 2', 'faltas parc. 2', 'inasistencias p2', 'faltasp2', 'falta p2', 'inasistencias 2'],
      'Faltas P3': ['faltas p3', 'faltas del parcial 3', 'falta parcial 3', 'faltas parc 3', 'faltas parc. 3', 'inasistencias p3', 'faltasp3', 'falta p3', 'inasistencias 3'],
      
      // Segundo: Parciales Finales (más específicos)
      'Parcial Final 1': ['parcial final 1', 'pf1', 'final 1', 'pf 1', 'parcialfinal1', 'p final 1', 'calif final 1', 'parc. final 1'],
      'Parcial Final 2': ['parcial final 2', 'pf2', 'final 2', 'pf 2', 'parcialfinal2', 'p final 2', 'calif final 2', 'parc. final 2'],
      'Parcial Final 3': ['parcial final 3', 'pf3', 'final 3', 'pf 3', 'parcialfinal3', 'p final 3', 'calif final 3', 'parc. final 3'],
      
      // Tercero: Parciales normales
      'Parcial 1': ['parcial 1', 'p1', 'parcial1', '1er parcial', 'primer parcial', 'parc 1', 'parc1', 'parc. 1', 'calif 1', 'calificacion 1'],
      'Parcial 2': ['parcial 2', 'p2', 'parcial2', '2do parcial', 'segundo parcial', 'parc 2', 'parc2', 'parc. 2', 'calif 2', 'calificacion 2'],
      'Parcial 3': ['parcial 3', 'p3', 'parcial3', '3er parcial', 'tercer parcial', 'parc 3', 'parc3', 'parc. 3', 'calif 3', 'calificacion 3'],
      
      // Cuarto: Nombres específicos
      'Nombre': ['alumno', 'nombre alumno', 'nombre del alumno', 'nombre completo', 'nombres', 'nombre', 'name', 'estudiante'],
      'Profesor': ['nombre del profesor', 'nombre profesor', 'docente', 'profesor', 'teacher', 'maestro', 'prof'],
      'Tutor': ['nombre del tutor', 'nombre tutor', 'asesor', 'tutor'],
      
      // Quinto: Grupos y Generación
      'Generación': ['generacion', 'generación', 'gen', 'cohorte', 'año de ingreso', 'año ingreso', 'promocion', 'año', 'generation'],
      'Grupo Materia': ['grupo materia', 'grupo de materia', 'grupo de la materia', 'grupo mat', 'grupo asignatura', 'grupo curso'],
      'Grupo': ['tipo grupo', 'grupo generacional', 'grupo alumno', 'grupo general', 'grupo'],
      
      // Sexto: Otros campos
      'ID': ['id', 'no', 'numero', 'number', '#', 'no.'],
      'Matrícula': ['matricula', 'matrícula', 'mat', 'matricula del alumno', 'clave', 'codigo', 'matrícula del alumno'],
      'Género': ['genero', 'género', 'sexo', 'sex', 'género del alumno', 'género alumno'],
      'Carrera': ['carrera', 'programa', 'licenciatura', 'programa educativo', 'carrera alumno'],
      'Materia': ['nombre de la materia', 'nombre materia', 'asignatura', 'materia', 'subject', 'asignatura/materia', 'nombre de asignatura'],
      'Tipo Curso': ['tipo de curso', 'tipo curso', 'tipo_curso', 'recursamiento', 'tipo'],
    };

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      for (final entry in mappings.entries) {
        // Solo mapear si no está ya asignado
        if (!_columnMapping.containsKey(entry.key)) {
          if (entry.value.any((pattern) => header == pattern || header.contains(pattern))) {
            _columnMapping[entry.key] = i;
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Importación'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildConfigForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetSelector(),
          const SizedBox(height: 24),
          _buildColumnMapper(),
          const SizedBox(height: 24),
          _buildPreview(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildSheetSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Hoja',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSheet,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Hoja del Excel',
              ),
              items: _sheetNames.map((String sheet) {
                return DropdownMenuItem(
                  value: sheet,
                  child: Text(sheet),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSheet = newValue;
                  _autoMapColumns();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnMapper() {
    if (_selectedSheet == null) return const SizedBox.shrink();

    final headers = _sheetHeaders[_selectedSheet!] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mapear Columnas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _autoMapColumns();
                    });
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Auto-mapear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._requiredFields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        field,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        value: _columnMapping[field],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          labelText: 'Columna',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('-- Sin mapear --'),
                          ),
                          ...headers.asMap().entries.map((entry) {
                            return DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text(
                                '${entry.key + 1}. ${entry.value}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (int? value) {
                          setState(() {
                            if (value == null) {
                              _columnMapping.remove(field);
                            } else {
                              _columnMapping[field] = value;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_selectedSheet == null || _excel == null) {
      return const SizedBox.shrink();
    }

    final sheet = _excel!.tables[_selectedSheet!]!;
    final rows = sheet.rows.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vista Previa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: (rows.isNotEmpty ? rows[0] : [])
                    .map((cell) => DataColumn(
                          label: Text(
                            cell?.value?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
                rows: rows.skip(1).map((row) {
                  return DataRow(
                    cells: row
                        .map((cell) => DataCell(
                              Text(cell?.value?.toString() ?? ''),
                            ))
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final mappedCount = _columnMapping.length;
    final requiredCount = _requiredFields.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: mappedCount >= requiredCount * 0.7
              ? Colors.green.shade50
              : Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  mappedCount >= requiredCount * 0.7
                      ? Icons.check_circle
                      : Icons.warning,
                  color: mappedCount >= requiredCount * 0.7
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$mappedCount de $requiredCount campos mapeados',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: mappedCount > 0 ? _proceedToImport : null,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Carga hojas y encabezados desde un archivo BIFF8/OLE2 (.xls real).
  void _loadFromBiff8(Uint8List bytes) {
    _excel = null; // sin Excel object → preview se oculta automáticamente
    final reader = XlsReader.fromBytes(bytes);
    if (reader.sheetCount == 0) {
      throw Exception('El archivo no contiene hojas de cálculo');
    }
    _sheetNames = reader.sheetNames;
    for (int i = 0; i < reader.sheetCount; i++) {
      final xlsSheet = reader.sheet(i);
      final name = _sheetNames[i];
      if (xlsSheet.rowCount > 0) {
        _sheetHeaders[name] = xlsSheet
            .row(xlsSheet.firstRow)
            .map((v) => v?.toString() ?? '')
            .toList();
      }
    }
  }

  void _proceedToImport() {
    if (_selectedSheet == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ImportScreen(
          filePath: widget.filePath,
          sheetName: _selectedSheet!,
          columnMapping: _columnMapping,
        ),
      ),
    );
  }
}
