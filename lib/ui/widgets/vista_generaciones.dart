import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../screens/group_detail_screen.dart';

class VistaGeneraciones extends StatefulWidget {
  const VistaGeneraciones({super.key});

  @override
  State<VistaGeneraciones> createState() => _VistaGeneracionesState();
}

class _VistaGeneracionesState extends State<VistaGeneraciones> {
  String? _generacionSeleccionada;
  String? _grupoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final generaciones = dataProvider.generacionesDisponibles;

        if (generaciones.isEmpty) {
          return const Center(
            child: Text('No hay datos de generaciones disponibles'),
          );
        }

        return Column(
          children: [
            // Selector de Generación
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar Generación',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: generaciones.map((gen) {
                        final isSelected = _generacionSeleccionada == gen;
                        return ChoiceChip(
                          label: Text('Generación $gen'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _generacionSeleccionada = selected ? gen : null;
                              _grupoSeleccionado = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Estadísticas de la Generación
            if (_generacionSeleccionada != null)
              _buildEstadisticasGeneracion(dataProvider, _generacionSeleccionada!),

            // Grupos de la Generación
            if (_generacionSeleccionada != null)
              Expanded(
                child: _buildGruposGeneracion(dataProvider, _generacionSeleccionada!),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEstadisticasGeneracion(DataProvider dataProvider, String generacion) {
    final stats = dataProvider.estadisticasPorGeneracion(generacion);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generación $generacion',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  'Total Alumnos',
                  '${stats['totalAlumnos']}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatChip(
                  'Aprobados',
                  '${stats['aprobados']}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatChip(
                  'Reprobados',
                  '${stats['reprobados']}',
                  Icons.cancel,
                  Colors.red,
                ),
                _buildStatChip(
                  'Promedio',
                  '${stats['promedioGeneral'].toStringAsFixed(2)}',
                  Icons.school,
                  Colors.orange,
                ),
                _buildStatChip(
                  'Grupos',
                  '${stats['grupos']}',
                  Icons.group_work,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildGruposGeneracion(DataProvider dataProvider, String generacion) {
    final grupos = dataProvider.gruposPorGeneracion(generacion);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grupos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${grupos.length} grupos',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: grupos.length,
              itemBuilder: (context, index) {
                final grupo = grupos[index];
                return _buildGrupoCard(dataProvider, generacion, grupo);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupoCard(DataProvider dataProvider, String generacion, String grupo) {
    final alumnosGrupo = dataProvider.alumnosPorGrupo(grupo);
    final gruposMateria = dataProvider.gruposMateriaDeGrupo(grupo);
    
    // Calcular estadísticas del grupo
    final matriculasUnicas = alumnosGrupo.map((a) => a.matricula).toSet().length;
    final materiasUnicas = alumnosGrupo.map((a) => a.nombreMateria).toSet().length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(grupo.substring(0, grupo.length > 3 ? 3 : grupo.length)),
        ),
        title: Text(
          grupo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$matriculasUnicas alumnos • $materiasUnicas materias',
        ),
        children: [
          if (gruposMateria.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grupos Materia:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gruposMateria.map((gm) {
                      final alumnosGM = dataProvider.alumnosPorGrupoMateria(gm);
                      final recursadores = dataProvider.detectarRecursadoresEnGrupoMateria(gm);
                      final tieneRecursadores = recursadores.isNotEmpty;
                      
                      return ActionChip(
                        avatar: tieneRecursadores
                            ? const Icon(Icons.warning, size: 16, color: Colors.orange)
                            : const Icon(Icons.check, size: 16, color: Colors.green),
                        label: Text(gm),
                        tooltip: tieneRecursadores
                            ? 'Tiene ${recursadores.length} recursador(es) de otras generaciones'
                            : 'Todos los alumnos son de la misma generación',
                        onPressed: () {
                          _mostrarDetalleGrupoMateria(context, dataProvider, gm, recursadores);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text('Ver Detalles del Grupo'),
                  onPressed: () {
                    // Navegar a la vista de detalle del grupo
                    _mostrarDetalleGrupo(context, dataProvider, grupo);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleGrupoMateria(
    BuildContext context,
    DataProvider dataProvider,
    String grupoMateria,
    List recursadores,
  ) {
    final alumnosGrupoMateria = dataProvider.alumnosPorGrupoMateria(grupoMateria);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grupo Materia: $grupoMateria'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total alumnos: ${alumnosGrupoMateria.length}'),
              const SizedBox(height: 8),
              if (recursadores.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Recursadores (${recursadores.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ...recursadores.map((alumno) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${alumno.nombre} (${alumno.matricula}) - Gen: ${alumno.generacion}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleGrupo(BuildContext context, DataProvider dataProvider, String grupo) {
    // Por ahora mostrar un diálogo simple, pero podrías navegar a una pantalla completa
    final alumnosGrupo = dataProvider.alumnosPorGrupo(grupo);
    final materias = alumnosGrupo.map((a) => a.nombreMateria).toSet().toList()..sort();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grupo: $grupo'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alumnos únicos: ${alumnosGrupo.map((a) => a.matricula).toSet().length}'),
              const SizedBox(height: 16),
              const Text(
                'Materias:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...materias.map((materia) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $materia', style: const TextStyle(fontSize: 12)),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
