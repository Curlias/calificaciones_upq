import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'student_profile_screen.dart';
import '../../providers/data_provider.dart';
import '../../providers/config_provider.dart';
import '../../models/reporte.dart';
import '../../services/pdf_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _filtroSeleccionado = 'todos';
  String _tipoReporte = 'individual';
  bool _generandoReporte = false;
  String? _carpetaDestino;

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataProvider, ConfigProvider>(
      builder: (context, dataProvider, configProvider, child) {
        if (!dataProvider.tieneDatos) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay datos para generar reportes',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Importe un archivo Excel primero',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generación de Reportes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              
              // Opciones de reporte
              _buildOpcionesReporte(dataProvider, configProvider),
              
              const SizedBox(height: 24),
              
              // Vista previa y generación
              _buildVistaPrevia(dataProvider, configProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcionesReporte(DataProvider dataProvider, ConfigProvider configProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opciones de Reporte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tipo de reporte
            Row(
              children: [
                const Text('Tipo de reporte:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'individual',
                        label: Text('Individual'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: 'grupo',
                        label: Text('Por Grupo'),
                        icon: Icon(Icons.groups),
                      ),
                      ButtonSegment(
                        value: 'general',
                        label: Text('General'),
                        icon: Icon(Icons.assessment),
                      ),
                    ],
                    selected: {_tipoReporte},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _tipoReporte = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Filtros
            Row(
              children: [
                const Text('Filtrar por:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroSeleccionado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      const DropdownMenuItem(value: 'aprobados', child: Text('Solo Aprobados')),
                      const DropdownMenuItem(value: 'reprobados', child: Text('Solo Reprobados')),
                      const DropdownMenuItem(value: 'recursamiento', child: Text('Solo Recursamiento')),
                      if (dataProvider.generacionesDisponibles.isNotEmpty) ...[
                        const DropdownMenuItem(
                          value: 'divider_generaciones',
                          enabled: false,
                          child: Divider(),
                        ),
                        ...dataProvider.generacionesDisponibles.map((gen) =>
                          DropdownMenuItem(value: 'generacion_$gen', child: Text('Generación: $gen')),
                        ),
                      ],
                      ...dataProvider.carreras.map((carrera) =>
                        DropdownMenuItem(value: 'carrera_$carrera', child: Text('Carrera: $carrera')),
                      ),
                      ...dataProvider.materias.map((materia) =>
                        DropdownMenuItem(value: 'materia_$materia', child: Text('Materia: $materia')),
                      ),
                      ...dataProvider.grupos.map((grupo) => grupo.nombre).toSet().map((grupoNombre) =>
                        DropdownMenuItem(value: 'grupo_$grupoNombre', child: Text('Grupo: $grupoNombre')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroSeleccionado = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Configuración de reporte
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Incluir logo'),
                    value: configProvider.incluirLogosEnReportes,
                    onChanged: (value) {
                      configProvider.incluirLogosEnReportes = value ?? false;
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Incluir firma'),
                    value: configProvider.incluirFirmaEnReportes,
                    onChanged: (value) {
                      configProvider.incluirFirmaEnReportes = value ?? false;
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Selector de carpeta destino
            OutlinedButton.icon(
              onPressed: _seleccionarCarpetaDestino,
              icon: const Icon(Icons.folder_open),
              label: Text(_carpetaDestino == null 
                ? 'Seleccionar carpeta de destino' 
                : 'Destino: ${_carpetaDestino!.split('/').last}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            if (_carpetaDestino != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _carpetaDestino!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaPrevia(DataProvider dataProvider, ConfigProvider configProvider) {
    final datosFiltrados = _aplicarFiltros(dataProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vista Previa del Reporte',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _generandoReporte ? null : () => _generarReporte(dataProvider, configProvider),
                  icon: _generandoReporte 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_generandoReporte ? 'Generando...' : 'Generar PDF'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Información del reporte
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getTipoReporteIcon(), color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        _getTipoReporteTexto(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Filtro aplicado: ${_getFiltroTexto()}'),
                  Text('Registros a incluir: ${_getConteoRegistros(datosFiltrados)}'),
                  Text('Institución: ${configProvider.nombreInstitucion}'),
                  if (configProvider.incluirLogosEnReportes && configProvider.logoPath != null)
                    const Text('✓ Se incluirá logo institucional'),
                  if (configProvider.incluirFirmaEnReportes && configProvider.textoFirma.isNotEmpty)
                    Text('✓ Se incluirá firma: ${configProvider.textoFirma}'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de elementos a generar
            if (_tipoReporte == 'individual')
              _buildListaAlumnos(datosFiltrados['alumnos'] ?? [])
            else if (_tipoReporte == 'grupo')
              _buildListaGrupos(datosFiltrados['grupos'] ?? [])
            else
              _buildResumenGeneral(dataProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildListaAlumnos(List<dynamic> alumnos) {
    if (alumnos.isEmpty) {
      return const Text('No hay alumnos que cumplan con los filtros seleccionados');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alumnos a incluir (${alumnos.length}):',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: alumnos.length > 20 ? 20 : alumnos.length,
            itemBuilder: (context, index) {
              final alumno = alumnos[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: alumno.aprueba() ? Colors.green : Colors.red,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(alumno.nombre),
                subtitle: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StudentProfileScreen(
                              matricula: alumno.matricula,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        alumno.matricula,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(' - ${alumno.nombreMateria}'),
                  ],
                ),
                trailing: Text(
                  alumno.calcularCalificacionFinalCalculada()?.toStringAsFixed(2) ?? 'S/C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: alumno.aprueba() ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
        ),
        if (alumnos.length > 20)
          Text(
            '... y ${alumnos.length - 20} más',
            style: TextStyle(color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildListaGrupos(List<dynamic> grupos) {
    if (grupos.isEmpty) {
      return const Text('No hay grupos que cumplan con los filtros seleccionados');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grupos a incluir (${grupos.length}):',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...grupos.map((grupo) => ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: grupo.porcentajeAprobados() >= 70 ? Colors.green : Colors.orange,
            child: Text(
              '${grupo.porcentajeAprobados().toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          title: Text('${grupo.nombre} - ${grupo.nombreMateria}'),
          subtitle: Text('Profesor: ${grupo.nombreProfesor}'),
          trailing: Text(
            '${grupo.totalAlumnos} alumnos\nPromedio: ${grupo.promedioGeneral.toStringAsFixed(2)}',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12),
          ),
        )),
      ],
    );
  }

  Widget _buildResumenGeneral(DataProvider dataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reporte General Institucional:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total de registros: ${dataProvider.totalAlumnos}'),
              Text('Total de grupos: ${dataProvider.totalGrupos}'),
              Text('Total de materias: ${dataProvider.totalMaterias}'),
              Text('Promedio institucional: ${dataProvider.promedioGeneral.toStringAsFixed(2)}'),
              Text('Aprobados: ${dataProvider.totalAprobados}'),
              Text('Reprobados: ${dataProvider.totalReprobados}'),
              if (dataProvider.totalSinCalificar > 0)
                Text('Sin calificar: ${dataProvider.totalSinCalificar}'),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, List<dynamic>> _aplicarFiltros(DataProvider dataProvider) {
    List<dynamic> alumnos = List.from(dataProvider.alumnos);
    List<dynamic> grupos = List.from(dataProvider.grupos);

    if (_filtroSeleccionado != 'todos' && _filtroSeleccionado != 'divider_generaciones') {
      if (_filtroSeleccionado == 'aprobados') {
        alumnos = alumnos.where((a) => a.aprueba()).toList();
      } else if (_filtroSeleccionado == 'reprobados') {
        alumnos = alumnos.where((a) {
          final cal = a.calcularCalificacionFinalCalculada();
          return cal != null && cal < 7.0;
        }).toList();
      } else if (_filtroSeleccionado == 'recursamiento') {
        alumnos = alumnos.where((a) => a.esRecursamiento).toList();
      } else if (_filtroSeleccionado.startsWith('generacion_')) {
        final generacion = _filtroSeleccionado.substring(11);
        alumnos = alumnos.where((a) => a.generacion == generacion).toList();
      } else if (_filtroSeleccionado.startsWith('grupo_')) {
        final grupo = _filtroSeleccionado.substring(6);
        alumnos = alumnos.where((a) => a.grupo == grupo).toList();
      } else if (_filtroSeleccionado.startsWith('carrera_')) {
        final carrera = _filtroSeleccionado.substring(8);
        alumnos = alumnos.where((a) => a.carrera == carrera).toList();
      } else if (_filtroSeleccionado.startsWith('materia_')) {
        final materia = _filtroSeleccionado.substring(8);
        alumnos = alumnos.where((a) => a.nombreMateria == materia).toList();
      }

      // Filtrar grupos basándose en alumnos filtrados
      final materiasGruposFiltrados = alumnos
          .map((a) => '${a.grupo}_${a.nombreMateria}')
          .toSet();

      grupos = grupos.where((grupo) {
        final claveGrupo = '${grupo.nombre}_${grupo.nombreMateria}';
        return materiasGruposFiltrados.contains(claveGrupo);
      }).toList();
    }

    return {
      'alumnos': alumnos,
      'grupos': grupos,
    };
  }

  String _getConteoRegistros(Map<String, List<dynamic>> datos) {
    if (_tipoReporte == 'individual') {
      return '${datos['alumnos']?.length ?? 0} alumnos';
    } else if (_tipoReporte == 'grupo') {
      return '${datos['grupos']?.length ?? 0} grupos';
    }
    return '1 reporte general';
  }

  IconData _getTipoReporteIcon() {
    switch (_tipoReporte) {
      case 'individual':
        return Icons.person;
      case 'grupo':
        return Icons.groups;
      case 'general':
        return Icons.assessment;
      default:
        return Icons.description;
    }
  }

  String _getTipoReporteTexto() {
    switch (_tipoReporte) {
      case 'individual':
        return 'Reportes Individuales de Alumnos';
      case 'grupo':
        return 'Reportes por Grupo';
      case 'general':
        return 'Reporte General Institucional';
      default:
        return 'Reporte';
    }
  }

  String _getFiltroTexto() {
    if (_filtroSeleccionado == 'todos') return 'Todos los registros';
    if (_filtroSeleccionado == 'aprobados') return 'Solo aprobados';
    if (_filtroSeleccionado == 'reprobados') return 'Solo reprobados';
    if (_filtroSeleccionado == 'recursamiento') return 'Solo recursamiento';
    if (_filtroSeleccionado.startsWith('generacion_')) {
      return 'Generación: ${_filtroSeleccionado.substring(11)}';
    }
    if (_filtroSeleccionado.startsWith('grupo_')) {
      return 'Grupo: ${_filtroSeleccionado.substring(6)}';
    }
    if (_filtroSeleccionado.startsWith('carrera_')) {
      return 'Carrera: ${_filtroSeleccionado.substring(8)}';
    }
    if (_filtroSeleccionado.startsWith('materia_')) {
      return 'Materia: ${_filtroSeleccionado.substring(8)}';
    }
    return _filtroSeleccionado;
  }

  Future<void> _seleccionarCarpetaDestino() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _carpetaDestino = selectedDirectory;
      });
    }
  }

  Future<void> _generarReporte(DataProvider dataProvider, ConfigProvider configProvider) async {
    if (_carpetaDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una carpeta de destino'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _generandoReporte = true;
    });

    try {
      final datosFiltrados = _aplicarFiltros(dataProvider);
      
      if (_tipoReporte == 'individual') {
        await _generarReportesIndividuales(datosFiltrados['alumnos'] ?? [], configProvider);
      } else if (_tipoReporte == 'grupo') {
        await _generarReportesGrupo(datosFiltrados['grupos'] ?? [], configProvider);
      } else {
        await _generarReporteGeneral(dataProvider, configProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reportes generados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reportes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _generandoReporte = false;
      });
    }
  }

  Future<void> _generarReportesIndividuales(List<dynamic> alumnos, ConfigProvider configProvider) async {
    for (int i = 0; i < alumnos.length; i++) {
      final alumno = alumnos[i];
      final reporte = ReporteAlumno(
        alumno: alumno,
        fechaGeneracion: DateTime.now(),
      );

      final pdfBytes = await PdfService.generarReporteAlumno(
        reporte: reporte,
        logoPath: configProvider.logoPath,
        nombreInstitucion: configProvider.nombreInstitucion,
        incluirFirma: configProvider.incluirFirmaEnReportes,
        textoFirma: configProvider.textoFirma,
      );

      final nombreArchivo = 'reporte_${alumno.matricula}_${alumno.nombre.replaceAll(' ', '_')}.pdf';
      final rutaCompleta = '$_carpetaDestino/$nombreArchivo';
      final file = File(rutaCompleta);
      await file.writeAsBytes(pdfBytes);
    }
  }

  Future<void> _generarReportesGrupo(List<dynamic> grupos, ConfigProvider configProvider) async {
    for (final grupo in grupos) {
      final reporte = ReporteGrupo(
        grupo: grupo,
        fechaGeneracion: DateTime.now(),
      );

      final pdfBytes = await PdfService.generarReporteGrupo(
        reporte: reporte,
        logoPath: configProvider.logoPath,
        nombreInstitucion: configProvider.nombreInstitucion,
        incluirFirma: configProvider.incluirFirmaEnReportes,
        textoFirma: configProvider.textoFirma,
      );

      final nombreArchivo = 'reporte_grupo_${grupo.nombre}_${grupo.nombreMateria.replaceAll(' ', '_')}.pdf';
      final rutaCompleta = '$_carpetaDestino/$nombreArchivo';
      final file = File(rutaCompleta);
      await file.writeAsBytes(pdfBytes);
    }
  }

  Future<void> _generarReporteGeneral(DataProvider dataProvider, ConfigProvider configProvider) async {
    // TODO: Implementar reporte general
    throw UnimplementedError('Reporte general en desarrollo');
  }
}