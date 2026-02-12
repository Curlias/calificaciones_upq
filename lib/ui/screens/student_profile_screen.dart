import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/alumno.dart';
import '../../providers/data_provider.dart';
import '../widgets/app_drawer.dart';

class StudentProfileScreen extends StatelessWidget {
  final String matricula;

  const StudentProfileScreen({
    super.key,
    required this.matricula,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil del Alumno - $matricula'),
        backgroundColor: const Color(0xFF151830),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Regresar',
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          // Filtrar todas las materias del alumno por matrícula
          final materiasAlumno = dataProvider.alumnos
              .where((alumno) => alumno.matricula == matricula)
              .toList();

          if (materiasAlumno.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron datos para la matrícula: $matricula',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final alumno = materiasAlumno.first;
          final estadisticas = _calcularEstadisticasAlumno(materiasAlumno);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(alumno, estadisticas),
                const SizedBox(height: 16),
                _buildEstadisticasGenerales(estadisticas),
                const SizedBox(height: 16),
                _buildGraficaRendimiento(materiasAlumno),
                const SizedBox(height: 16),
                _buildGraficaAsistencia(materiasAlumno),
                const SizedBox(height: 16),
                _buildListaMaterias(materiasAlumno),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calcularEstadisticasAlumno(List<Alumno> materias) {
    double sumaCalificaciones = 0;
    int totalFaltas = 0;
    int materiasAprobadas = 0;
    int materiasReprobadas = 0;
    int materiasSinCalificar = 0;
    int contadorCalificaciones = 0;

    for (final materia in materias) {
      final calificacion = materia.calcularCalificacionFinalCalculada();
      if (calificacion != null) {
        sumaCalificaciones += calificacion;
        contadorCalificaciones++;
        if (calificacion >= 7.0) {
          materiasAprobadas++;
        } else {
          materiasReprobadas++;
        }
      } else {
        materiasSinCalificar++;
      }

      totalFaltas += materia.faltasP1 + materia.faltasP2 + materia.faltasP3;
    }

    final promedioGeneral = contadorCalificaciones > 0
        ? sumaCalificaciones / contadorCalificaciones
        : 0.0;

    return {
      'promedioGeneral': promedioGeneral,
      'totalFaltas': totalFaltas,
      'materiasAprobadas': materiasAprobadas,
      'materiasReprobadas': materiasReprobadas,
      'materiasSinCalificar': materiasSinCalificar,
      'totalMaterias': materias.length,
    };
  }

  Widget _buildHeaderCard(Alumno alumno, Map<String, dynamic> stats) {
    final generoTexto = alumno.genero == 'M' ? 'Masculino' : 'Femenino';
    final iconoGenero = alumno.genero == 'M' ? Icons.man : Icons.woman;
    final colorGenero = alumno.genero == 'M' ? Colors.blue : Colors.pink;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorGenero.withOpacity(0.2),
                  child: Icon(iconoGenero, size: 50, color: colorGenero),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumno.nombre,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Matrícula: ${alumno.matricula}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(iconoGenero, size: 16, color: colorGenero),
                          const SizedBox(width: 4),
                          Text(
                            generoTexto,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.school, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alumno.carrera,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.group, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Grupo: ${alumno.grupo}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  'Promedio',
                  stats['promedioGeneral'].toStringAsFixed(2),
                  Icons.grade,
                  stats['promedioGeneral'] >= 7.0 ? Colors.green : Colors.red,
                ),
                _buildStatChip(
                  'Materias',
                  '${stats['totalMaterias']}',
                  Icons.book,
                  Colors.blue,
                ),
                _buildStatChip(
                  'Faltas',
                  '${stats['totalFaltas']}',
                  Icons.event_busy,
                  Colors.orange,
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasGenerales(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas Generales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEstadRow(
              'Materias Aprobadas',
              '${stats['materiasAprobadas']}',
              Colors.green,
              Icons.check_circle,
            ),
            _buildEstadRow(
              'Materias Reprobadas',
              '${stats['materiasReprobadas']}',
              Colors.red,
              Icons.cancel,
            ),
            _buildEstadRow(
              'Sin Calificar',
              '${stats['materiasSinCalificar']}',
              Colors.grey,
              Icons.help_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficaRendimiento(List<Alumno> materias) {
    final data = materias.map((materia) {
      final cal = materia.calcularCalificacionFinalCalculada() ?? 0.0;
      return MateriaRendimiento(
        materia.nombreMateria,
        cal,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rendimiento por Materia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelStyle: const TextStyle(fontSize: 9),
                  labelIntersectAction: AxisLabelIntersectAction.multipleRows,
                  maximumLabelWidth: 120,
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: 10,
                  interval: 2,
                ),
                series: <CartesianSeries>[
                  ColumnSeries<MateriaRendimiento, String>(
                    dataSource: data,
                    xValueMapper: (MateriaRendimiento data, _) => data.materia,
                    yValueMapper: (MateriaRendimiento data, _) => data.calificacion,
                    pointColorMapper: (MateriaRendimiento data, _) =>
                        data.calificacion >= 7.0 ? Colors.green : Colors.red,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficaAsistencia(List<Alumno> materias) {
    final data = materias.map((materia) {
      final totalFaltas = materia.faltasP1 + materia.faltasP2 + materia.faltasP3;
      return MateriaAsistencia(
        materia.nombreMateria,
        totalFaltas,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faltas por Materia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelStyle: const TextStyle(fontSize: 9),
                  labelIntersectAction: AxisLabelIntersectAction.multipleRows,
                  maximumLabelWidth: 120,
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                ),
                series: <CartesianSeries>[
                  BarSeries<MateriaAsistencia, String>(
                    dataSource: data,
                    xValueMapper: (MateriaAsistencia data, _) => data.materia,
                    yValueMapper: (MateriaAsistencia data, _) => data.faltas,
                    color: Colors.orange,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaMaterias(List<Alumno> materias) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de Materias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...materias.map((materia) => _buildMateriaCard(materia)),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriaCard(Alumno materia) {
    final calFinal = materia.calcularCalificacionFinalCalculada();
    final calP1 = materia.calcularCalificacionParcial(1);
    final calP2 = materia.calcularCalificacionParcial(2);
    final calP3 = materia.calcularCalificacionParcial(3);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          materia.nombreMateria,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Profesor: ${materia.nombreProfesor}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: calFinal != null
                ? (calFinal >= 7.0 ? Colors.green : Colors.red)
                : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            calFinal?.toStringAsFixed(1) ?? 'S/C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (materia.grupoMateria != null && materia.grupoMateria!.isNotEmpty)
                  _buildDetailRow('Grupo Materia:', materia.grupoMateria!),
                _buildDetailRow('Grupo:', materia.grupo),
                if (materia.esRecursamiento)
                  _buildDetailRow('Tipo:', 'Recursamiento', Colors.orange),
                const Divider(),
                const Text(
                  'Calificaciones por Parcial:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildParcialChip('P1', calP1, materia.faltasP1),
                    _buildParcialChip('P2', calP2, materia.faltasP2),
                    _buildParcialChip('P3', calP3, materia.faltasP3),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Faltas: ${materia.faltasP1 + materia.faltasP2 + materia.faltasP3}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: valueColor ?? Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcialChip(String parcial, double? cal, int faltas) {
    final color = cal != null ? (cal >= 7.0 ? Colors.green : Colors.red) : Colors.grey;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Column(
            children: [
              Text(
                parcial,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cal?.toStringAsFixed(1) ?? 'S/C',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faltas: $faltas',
          style: const TextStyle(fontSize: 10, color: Colors.orange),
        ),
      ],
    );
  }
}

class MateriaRendimiento {
  final String materia;
  final double calificacion;

  MateriaRendimiento(this.materia, this.calificacion);
}

class MateriaAsistencia {
  final String materia;
  final int faltas;

  MateriaAsistencia(this.materia, this.faltas);
}
