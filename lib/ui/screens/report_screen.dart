import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File, Platform, Process;
import 'student_profile_screen.dart';
import '../../providers/data_provider.dart';
import '../../providers/config_provider.dart';
import '../../models/alumno.dart';
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
  final Set<String> _alumnosSeleccionados = {};
  final Set<String> _gruposSeleccionados = {};

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
                        _alumnosSeleccionados.clear();
                        _gruposSeleccionados.clear();
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
                        _alumnosSeleccionados.clear();
                        _gruposSeleccionados.clear();
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
                  label: Text(_generandoReporte ? 'Generando...' : _getBotonLabel(datosFiltrados)),
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

  Widget _buildListaAlumnos(List<dynamic> alumnosRaw) {
    if (alumnosRaw.isEmpty) {
      return const Text('No hay alumnos con los filtros aplicados');
    }

    final Map<String, List<Alumno>> porMatricula = {};
    for (final a in alumnosRaw.cast<Alumno>()) {
      porMatricula.putIfAbsent(a.matricula, () => []).add(a);
    }
    final entradas = porMatricula.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${entradas.length} alumnos únicos',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_alumnosSeleccionados.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_alumnosSeleccionados.length} seleccionados',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() {
                _alumnosSeleccionados.clear();
                _alumnosSeleccionados.addAll(porMatricula.keys);
              }),
              icon: const Icon(Icons.check_box, size: 16),
              label: const Text('Todos', style: TextStyle(fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _alumnosSeleccionados.clear()),
              icon: const Icon(Icons.check_box_outline_blank, size: 16),
              label: const Text('Ninguno', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Sin selección = genera todos. Toca la matrícula para ver el perfil.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entradas.length,
            itemBuilder: (context, index) {
              final matricula = entradas[index].key;
              final materias = entradas[index].value;
              final nombre = materias.first.nombre;
              final carrera = materias.first.carrera;
              final grupo = materias.first.grupo;
              final cals = materias
                  .map((a) => a.calcularCalificacionFinalCalculada())
                  .whereType<double>()
                  .toList();
              final promedio = cals.isEmpty
                  ? null
                  : cals.reduce((a, b) => a + b) / cals.length;
              final aprobadas = cals.where((c) => c >= 7.0).length;
              final totalFaltas = materias.fold<int>(0, (s, a) => s + a.totalFaltas);
              final isSelected = _alumnosSeleccionados.contains(matricula);

              return InkWell(
                onTap: () => setState(() {
                  if (isSelected) {
                    _alumnosSeleccionados.remove(matricula);
                  } else {
                    _alumnosSeleccionados.add(matricula);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) => setState(() {
                          if (val == true) {
                            _alumnosSeleccionados.add(matricula);
                          } else {
                            _alumnosSeleccionados.remove(matricula);
                          }
                        }),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            (promedio ?? 0) >= 7.0
                                ? Colors.green
                                : Colors.red,
                        child: Text(
                          promedio?.toStringAsFixed(1) ?? '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre,
                                style:
                                    const TextStyle(fontSize: 13)),
                            Row(children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (_) => StudentProfileScreen(
                                      matricula: matricula),
                                )),
                                child: Text(
                                  matricula,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration:
                                        TextDecoration.underline,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '  •  $grupo  •  $aprobadas/${materias.length} apr  •  $totalFaltas faltas',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            promedio?.toStringAsFixed(2) ?? 'S/C',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: (promedio ?? 0) >= 7.0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            carrera.length > 14
                                ? '${carrera.substring(0, 14)}…'
                                : carrera,
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListaGrupos(List<dynamic> grupos) {
    if (grupos.isEmpty) {
      return const Text('No hay grupos con los filtros aplicados');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${grupos.length} grupos',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_gruposSeleccionados.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_gruposSeleccionados.length} seleccionados',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() {
                _gruposSeleccionados.clear();
                _gruposSeleccionados
                    .addAll(grupos.map((g) => g.nombre as String));
              }),
              icon: const Icon(Icons.check_box, size: 16),
              label: const Text('Todos', style: TextStyle(fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => _gruposSeleccionados.clear()),
              icon: const Icon(Icons.check_box_outline_blank, size: 16),
              label: const Text('Ninguno', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Sin selección = genera todos.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        ...grupos.map((grupo) {
          final key = grupo.nombre as String;
          final isSelected = _gruposSeleccionados.contains(key);
          final pct = grupo.porcentajeAprobados() as double;

          return InkWell(
            onTap: () => setState(() {
              if (isSelected) {
                _gruposSeleccionados.remove(key);
              } else {
                _gruposSeleccionados.add(key);
              }
            }),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) => setState(() {
                      if (val == true) {
                        _gruposSeleccionados.add(key);
                      } else {
                        _gruposSeleccionados.remove(key);
                      }
                    }),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: pct >= 70
                        ? Colors.green
                        : pct >= 50
                            ? Colors.orange
                            : Colors.red,
                    child: Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${grupo.nombre} — ${grupo.nombreMateria}',
                            style: const TextStyle(fontSize: 13)),
                        Text(
                          'Prof: ${grupo.nombreProfesor}  •  ${grupo.totalAlumnos} alumnos',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (grupo.promedioGeneral as double).toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: (grupo.promedioGeneral as double) >= 7.0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResumenGeneral(DataProvider dataProvider) {
    final estadCarrera = dataProvider.estadisticasPorCarrera;
    final materiasDif = dataProvider.materiasPorDificultad;
    final pctAprobados = dataProvider.totalAlumnos > 0
        ? dataProvider.totalAprobados / dataProvider.totalAlumnos * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen Institucional:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // Row 1: totals
        Row(children: [
          _buildMiniStatCard('Alumnos', '${dataProvider.totalAlumnos}', Icons.people, Colors.blue),
          const SizedBox(width: 8),
          _buildMiniStatCard('Grupos', '${dataProvider.totalGrupos}', Icons.groups, Colors.purple),
          const SizedBox(width: 8),
          _buildMiniStatCard('Materias', '${dataProvider.totalMaterias}', Icons.book, Colors.teal),
          const SizedBox(width: 8),
          _buildMiniStatCard('Promedio', dataProvider.promedioGeneral.toStringAsFixed(2), Icons.grade,
              dataProvider.promedioGeneral >= 7.0 ? Colors.green : Colors.red),
        ]),
        const SizedBox(height: 8),

        // Row 2: risk
        Row(children: [
          _buildMiniStatCard('Aprobados', '${dataProvider.totalAprobados}', Icons.check_circle, Colors.green),
          const SizedBox(width: 8),
          _buildMiniStatCard('Reprobados', '${dataProvider.totalReprobados}', Icons.cancel, Colors.red),
          const SizedBox(width: 8),
          _buildMiniStatCard('En riesgo', '${dataProvider.alumnosEnRiesgoGlobal.length}', Icons.warning, Colors.orange),
          const SizedBox(width: 8),
          _buildMiniStatCard('Extraordinario', '${dataProvider.totalNecesitanExtraordinario}', Icons.school, Colors.deepPurple),
        ]),

        const SizedBox(height: 16),

        // Overall approval bar
        Row(
          children: [
            const Text('Índice de aprobación global:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text('${pctAprobados.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: pctAprobados >= 70 ? Colors.green : Colors.orange)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pctAprobados / 100,
            minHeight: 10,
            color: pctAprobados >= 70 ? Colors.green : pctAprobados >= 50 ? Colors.orange : Colors.red,
            backgroundColor: Colors.grey[200],
          ),
        ),

        if (estadCarrera.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Por carrera:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...estadCarrera.entries.take(8).map((e) {
            final pct = e.value['porcentajeAprobados'] as double;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e.key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        '${e.value['totalAlumnos']} alumnos  •  ${(e.value['promedio'] as double).toStringAsFixed(2)}  •  ${pct.toStringAsFixed(1)}% apr.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 7,
                      color: pct >= 70 ? Colors.green : pct >= 50 ? Colors.orange : Colors.red,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        if (materiasDif.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Materias con menor promedio:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...materiasDif.take(6).map((m) {
            final prom = m['promedio'] as double;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: prom >= 7.0 ? Colors.green[100] : Colors.red[100],
                child: Text(
                  prom.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold,
                    color: prom >= 7.0 ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
              title: Text(m['materia'] as String, style: const TextStyle(fontSize: 13)),
              trailing: Text('${m['total']} alumnos', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
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
      final alumnos = datos['alumnos'] ?? [];
      final totalUnicos =
          alumnos.cast<Alumno>().map((a) => a.matricula).toSet().length;
      if (_alumnosSeleccionados.isNotEmpty) {
        return '${_alumnosSeleccionados.length} de $totalUnicos alumnos seleccionados';
      }
      return '$totalUnicos alumnos únicos (se generarán todos)';
    } else if (_tipoReporte == 'grupo') {
      final total = datos['grupos']?.length ?? 0;
      if (_gruposSeleccionados.isNotEmpty) {
        return '${_gruposSeleccionados.length} de $total grupos seleccionados';
      }
      return '$total grupos (se generarán todos)';
    }
    return '1 reporte general institucional';
  }

  String _getBotonLabel(Map<String, List<dynamic>> datos) {
    if (_tipoReporte == 'individual') {
      final count = _alumnosSeleccionados.isNotEmpty
          ? _alumnosSeleccionados.length
          : (datos['alumnos'] ?? [])
              .cast<Alumno>()
              .map((a) => a.matricula)
              .toSet()
              .length;
      return 'Generar $count PDF(s)';
    } else if (_tipoReporte == 'grupo') {
      final count = _gruposSeleccionados.isNotEmpty
          ? _gruposSeleccionados.length
          : datos['grupos']?.length ?? 0;
      return 'Generar $count PDF(s)';
    }
    return 'Generar PDF';
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
        _ofrecerAbrirCarpeta(_carpetaDestino!);
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

  void _ofrecerAbrirCarpeta(String carpeta) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reporte(s) generado(s) exitosamente'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Abrir carpeta',
          textColor: Colors.white,
          onPressed: () {
              if (Platform.isWindows) {
                Process.run('explorer', [carpeta]);
              } else if (Platform.isLinux) {
                Process.run('xdg-open', [carpeta]);
              } else {
                Process.run('open', [carpeta]);
              }
            },
        ),
      ),
    );
  }

  Future<void> _generarReportesIndividuales(
      List<dynamic> alumnosRaw, ConfigProvider configProvider) async {
    final Map<String, List<Alumno>> porMatricula = {};
    for (final a in alumnosRaw.cast<Alumno>()) {
      porMatricula.putIfAbsent(a.matricula, () => []).add(a);
    }

    final matriculasAGenerar = _alumnosSeleccionados.isNotEmpty
        ? porMatricula.keys
            .where((m) => _alumnosSeleccionados.contains(m))
            .toList()
        : porMatricula.keys.toList();

    for (final matricula in matriculasAGenerar) {
      final materias = porMatricula[matricula]!;
      final pdfBytes = await PdfService.generarReporteAlumnoCompleto(
        materias: materias,
        logoPath: configProvider.logoPath,
        nombreInstitucion: configProvider.nombreInstitucion,
        incluirFirma: configProvider.incluirFirmaEnReportes,
        textoFirma: configProvider.textoFirma,
      );
      final nombre = materias.first.nombre.replaceAll(' ', '_');
      final nombreArchivo = 'reporte_${matricula}_$nombre.pdf';
      await File('$_carpetaDestino/$nombreArchivo').writeAsBytes(pdfBytes);
    }
  }

  Future<void> _generarReportesGrupo(
      List<dynamic> grupos, ConfigProvider configProvider) async {
    final gruposAGenerar = _gruposSeleccionados.isNotEmpty
        ? grupos
            .where((g) => _gruposSeleccionados.contains(g.nombre as String))
            .toList()
        : grupos;

    for (final grupo in gruposAGenerar) {
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
    final pdfBytes = await PdfService.generarReporteGeneral(
      alumnos: dataProvider.alumnos,
      grupos: dataProvider.grupos,
      estadisticasPorCarrera: dataProvider.estadisticasPorCarrera,
      logoPath: configProvider.logoPath,
      nombreInstitucion: configProvider.nombreInstitucion,
      incluirFirma: configProvider.incluirFirmaEnReportes,
      textoFirma: configProvider.textoFirma,
    );
    final nombreArchivo = 'reporte_general_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final rutaCompleta = '$_carpetaDestino/$nombreArchivo';
    await File(rutaCompleta).writeAsBytes(pdfBytes);
  }
}