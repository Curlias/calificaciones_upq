import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../services/excel_service.dart';

class ImportScreen extends StatefulWidget {
  final String filePath;

  const ImportScreen({
    super.key,
    required this.filePath,
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isValidating = false;
  bool _isImporting = false;
  Map<String, dynamic>? _validationResult;
  Map<String, dynamic>? _importResult;

  @override
  void initState() {
    super.initState();
    _validateFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Archivo Excel'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del archivo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Archivo Seleccionado',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.filePath.split('/').last,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ruta: ${widget.filePath}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Validación del archivo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isValidating
                              ? Icons.hourglass_empty
                              : _validationResult != null
                                  ? (_validationResult!['valid'] ? Icons.check_circle : Icons.error)
                                  : Icons.help_outline,
                          color: _isValidating
                              ? Colors.orange
                              : _validationResult != null
                                  ? (_validationResult!['valid'] ? Colors.green : Colors.red)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Validación del Archivo',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isValidating)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Validando estructura del archivo...'),
                        ],
                      )
                    else if (_validationResult != null)
                      _buildValidationResults()
                    else
                      const Text('Esperando validación...'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Resultados de importación
            if (_importResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _importResult!['success'] ? Icons.check_circle : Icons.error,
                            color: _importResult!['success'] ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resultado de Importación',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_importResult!['message']),
                      if (_importResult!['success']) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Alumnos importados: ${_importResult!['alumnos']?.length ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Grupos creados: ${_importResult!['grupos']?.length ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            // Botones de acción
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
                    onPressed: _canImport() ? _importFile : null,
                    child: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Importar'),
                  ),
                ),
              ],
            ),

            if (_importResult != null && _importResult!['success']) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home),
                  label: const Text('Ir al Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResults() {
    final isValid = _validationResult!['valid'] as bool;
    final errors = _validationResult!['errors'] as List<String>;
    final warnings = _validationResult!['warnings'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isValid)
          const Row(
            children: [
              Icon(Icons.check, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text(
                'El archivo tiene una estructura válida',
                style: TextStyle(color: Colors.green),
              ),
            ],
          )
        else
          const Text(
            'Se encontraron problemas en el archivo:',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),

        if (errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Errores:',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          for (final error in errors)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
        ],

        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Advertencias:',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(warning, style: const TextStyle(color: Colors.orange))),
                ],
              ),
            ),
        ],
      ],
    );
  }

  bool _canImport() {
    return _validationResult != null &&
           _validationResult!['valid'] &&
           !_isImporting &&
           _importResult == null;
  }

  Future<void> _validateFile() async {
    setState(() {
      _isValidating = true;
    });

    try {
      final result = await ExcelService.validateExcelStructure(widget.filePath);
      setState(() {
        _validationResult = result;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _validationResult = {
          'valid': false,
          'errors': ['Error durante la validación: ${e.toString()}'],
          'warnings': <String>[],
        };
        _isValidating = false;
      });
    }
  }

  Future<void> _importFile() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final success = await dataProvider.cargarDatosDesdeExcel(widget.filePath);
      
      setState(() {
        _importResult = {
          'success': success,
          'message': success 
              ? 'Datos importados exitosamente'
              : dataProvider.mensajeError,
          'alumnos': success ? dataProvider.alumnos : null,
          'grupos': success ? dataProvider.grupos : null,
        };
        _isImporting = false;
      });

      if (success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dataProvider.totalAlumnos} registros importados correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _importResult = {
          'success': false,
          'message': 'Error inesperado durante la importación: ${e.toString()}',
          'alumnos': null,
          'grupos': null,
        };
        _isImporting = false;
      });
    }
  }
}