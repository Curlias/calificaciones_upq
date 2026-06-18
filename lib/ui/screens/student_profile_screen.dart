import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/alumno.dart';
import '../../providers/data_provider.dart';
import '../widgets/semaforo_badge.dart';

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
        title: Text('Perfil del Alumno — $matricula'),
        backgroundColor: const Color(0xFF151830),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
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
                    'No se encontraron datos para: $matricula',
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
                _buildRiskBanner(alumno),
                const SizedBox(height: 16),
                _buildEstadisticasGenerales(estadisticas, materiasAlumno),
                const SizedBox(height: 16),
                _buildEvolucionParciales(materiasAlumno),
                const SizedBox(height: 16),
                _buildGraficaRendimiento(materiasAlumno),
                const SizedBox(height: 16),
                _buildGraficaFaltas(materiasAlumno),
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
        if (calificacion >= 7.0) materiasAprobadas++; else materiasReprobadas++;
      } else {
        materiasSinCalificar++;
      }
      totalFaltas += materia.faltasP1 + materia.faltasP2 + materia.faltasP3;
    }

    return {
      'promedioGeneral': contadorCalificaciones > 0 ? sumaCalificaciones / contadorCalificaciones : 0.0,
      'totalFaltas': totalFaltas,
      'materiasAprobadas': materiasAprobadas,
      'materiasReprobadas': materiasReprobadas,
      'materiasSinCalificar': materiasSinCalificar,
      'totalMaterias': materias.length,
    };
  }

  Widget _buildRiskBanner(Alumno alumno) {
    if (alumno.estadoSemaforo == 'verde' || alumno.estadoSemaforo == 'gris') {
      return const SizedBox.shrink();
    }
    final badges = <Widget>[
      SemaforoBadge(estado: alumno.estadoSemaforo, size: 16, showLabel: true),
    ];
    if (alumno.necesitaExtraordinario) {
      badges.addAll([
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 14, color: Colors.purple),
              SizedBox(width: 4),
              Text('Requiere extraordinario',
                  style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ]);
    }
    final rango = alumno.rangoCalificacion;
    if (rango != 'S/C') {
      badges.addAll([
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Rango $rango',
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
        ),
      ]);
    }
    return Card(
      color: SemaforoBadge.colorDeEstado(alumno.estadoSemaforo).withOpacity(0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: SemaforoBadge.colorDeEstado(alumno.estadoSemaforo).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 0,
          runSpacing: 8,
          children: badges,
        ),
      ),
    );
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorGenero.withOpacity(0.2),
                      child: Icon(iconoGenero, size: 50, color: colorGenero),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SemaforoBadge(estado: alumno.estadoSemaforo, size: 18),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumno.nombre,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      _infoRow(Icons.badge, 'Matrícula: ${alumno.matricula}', Colors.grey[600]!),
                      _infoRow(iconoGenero, generoTexto, colorGenero),
                      _infoRow(Icons.school, alumno.carrera, Colors.grey[600]!),
                      _infoRow(Icons.group, 'Grupo: ${alumno.grupo}', Colors.grey[600]!),
                      if (alumno.generacion != null && alumno.generacion!.isNotEmpty)
                        _infoRow(Icons.calendar_today, 'Generación: ${alumno.generacion}', Colors.grey[600]!),
                      if (alumno.nombreTutor != null && alumno.nombreTutor!.isNotEmpty)
                        _infoRow(Icons.person_pin, 'Tutor: ${alumno.nombreTutor}', Colors.grey[600]!),
                      if (alumno.esRecursamiento)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Recursamiento', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
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
                _buildStatChip('Promedio',
                    (stats['promedioGeneral'] as double).toStringAsFixed(2),
                    Icons.grade,
                    (stats['promedioGeneral'] as double) >= 7.0 ? Colors.green : Colors.red),
                _buildStatChip('Materias', '${stats['totalMaterias']}', Icons.book, Colors.blue),
                _buildStatChip('Faltas', '${stats['totalFaltas']}', Icons.event_busy, Colors.orange),
                _buildStatChip('Aprobadas', '${stats['materiasAprobadas']}', Icons.check_circle, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEstadisticasGenerales(Map<String, dynamic> stats, List<Alumno> materias) {
    // Best and worst subject
    Alumno? mejor, peor;
    double mejorCal = -1, peorCal = 11;
    for (final m in materias) {
      final cal = m.calcularCalificacionFinalCalculada();
      if (cal != null) {
        if (cal > mejorCal) { mejorCal = cal; mejor = m; }
        if (cal < peorCal) { peorCal = cal; peor = m; }
      }
    }

    final totalFaltas = stats['totalFaltas'] as int;
    final maxFaltas = (materias.length * 9).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estadísticas Generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildEstadRow('Aprobadas', '${stats['materiasAprobadas']}', Colors.green, Icons.check_circle)),
                Expanded(child: _buildEstadRow('Reprobadas', '${stats['materiasReprobadas']}', Colors.red, Icons.cancel)),
                Expanded(child: _buildEstadRow('Sin Calificar', '${stats['materiasSinCalificar']}', Colors.grey, Icons.help_outline)),
              ],
            ),
            const Divider(height: 24),
            if (mejor != null) ...[
              _buildDestaqueRow(Icons.emoji_events, 'Mejor materia', mejor.nombreMateria, mejorCal, Colors.green),
              const SizedBox(height: 8),
            ],
            if (peor != null && mejor?.nombreMateria != peor?.nombreMateria) ...[
              _buildDestaqueRow(
                Icons.trending_down, 'Calificación más baja', peor!.nombreMateria, peorCal,
                peorCal >= 7.0 ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 12),
            ],
            const Divider(height: 0),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_busy, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text('Faltas totales: $totalFaltas${maxFaltas > 0 ? " / ${maxFaltas.toInt()}" : ""}',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxFaltas > 0 ? totalFaltas / maxFaltas : 0,
                      minHeight: 8,
                      color: totalFaltas == 0 ? Colors.green : totalFaltas <= maxFaltas * 0.33 ? Colors.orange : Colors.red,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestaqueRow(IconData icon, String label, String materia, double cal, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(materia, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(cal.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildEstadRow(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // ── Evolución por parciales ───────────────────────────────────────────────

  Widget _buildEvolucionParciales(List<Alumno> materias) {
    // Average per parcial across all subjects
    final calsP1 = <double>[];
    final calsP2 = <double>[];
    final calsP3 = <double>[];

    for (final m in materias) {
      final p1 = m.calcularCalificacionParcial(1);
      final p2 = m.calcularCalificacionParcial(2);
      final p3 = m.calcularCalificacionParcial(3);
      if (p1 != null) calsP1.add(p1);
      if (p2 != null) calsP2.add(p2);
      if (p3 != null) calsP3.add(p3);
    }

    final avgP1 = calsP1.isEmpty ? null : calsP1.reduce((a, b) => a + b) / calsP1.length;
    final avgP2 = calsP2.isEmpty ? null : calsP2.reduce((a, b) => a + b) / calsP2.length;
    final avgP3 = calsP3.isEmpty ? null : calsP3.reduce((a, b) => a + b) / calsP3.length;

    String tendencia = '— Sin datos';
    Color colorTendencia = Colors.grey;
    IconData iconTendencia = Icons.remove;
    if (avgP1 != null && avgP3 != null) {
      final diff = avgP3 - avgP1;
      if (diff > 0.3) {
        tendencia = '↑ Mejorando';
        colorTendencia = Colors.green;
        iconTendencia = Icons.trending_up;
      } else if (diff < -0.3) {
        tendencia = '↓ Bajando';
        colorTendencia = Colors.red;
        iconTendencia = Icons.trending_down;
      } else {
        tendencia = '→ Estable';
        colorTendencia = Colors.blue;
        iconTendencia = Icons.trending_flat;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Evolución por Parciales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorTendencia.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorTendencia.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconTendencia, size: 16, color: colorTendencia),
                      const SizedBox(width: 4),
                      Text(tendencia, style: TextStyle(color: colorTendencia, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Average per parcial boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildParcialAvg('Parcial 1', avgP1),
                _buildTrendArrow(avgP1, avgP2),
                _buildParcialAvg('Parcial 2', avgP2),
                _buildTrendArrow(avgP2, avgP3),
                _buildParcialAvg('Parcial 3', avgP3),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Detalle por materia:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),

            // Per-subject breakdown
            ...materias.map((m) => _buildMateriaEvolucion(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildParcialAvg(String label, double? avg) {
    final color = avg == null ? Colors.grey : (avg >= 7.0 ? Colors.green : Colors.red);
    return Column(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Text(avg?.toStringAsFixed(1) ?? 'S/C',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text('prom.', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTrendArrow(double? from, double? to) {
    if (from == null || to == null) {
      return const Icon(Icons.arrow_forward, color: Colors.grey, size: 18);
    }
    final diff = to - from;
    Color color;
    IconData icon;
    if (diff > 0.2) { color = Colors.green; icon = Icons.trending_up; }
    else if (diff < -0.2) { color = Colors.red; icon = Icons.trending_down; }
    else { color = Colors.blue; icon = Icons.trending_flat; }
    return Icon(icon, color: color, size: 22);
  }

  Widget _buildMateriaEvolucion(Alumno m) {
    final p1 = m.calcularCalificacionParcial(1);
    final p2 = m.calcularCalificacionParcial(2);
    final p3 = m.calcularCalificacionParcial(3);

    Color _c(double? v) => v == null ? Colors.grey[400]! : (v >= 7.0 ? Colors.green : Colors.red);
    String _s(double? v) => v?.toStringAsFixed(1) ?? 'S/C';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(m.nombreMateria, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
          _miniParcialBox(_s(p1), _c(p1)),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          _miniParcialBox(_s(p2), _c(p2)),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          _miniParcialBox(_s(p3), _c(p3)),
        ],
      ),
    );
  }

  Widget _miniParcialBox(String value, Color color) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 3),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(value,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  // ── Gráficas ─────────────────────────────────────────────────────────────

  Widget _buildGraficaRendimiento(List<Alumno> materias) {
    final data = materias.map((m) {
      final cal = m.calcularCalificacionFinalCalculada() ?? 0.0;
      return _MateriaData(m.nombreMateria, cal);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calificación Final por Materia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -30,
                  labelStyle: const TextStyle(fontSize: 9),
                  labelIntersectAction: AxisLabelIntersectAction.multipleRows,
                  maximumLabelWidth: 80,
                ),
                primaryYAxis: NumericAxis(minimum: 0, maximum: 10, interval: 2),
                plotAreaBorderWidth: 0,
                series: <CartesianSeries>[
                  ColumnSeries<_MateriaData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    pointColorMapper: (d, _) => d.value >= 7.0 ? Colors.green : Colors.red,
                    dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 9)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficaFaltas(List<Alumno> materias) {
    final hayFaltas = materias.any((m) => m.faltasP1 + m.faltasP2 + m.faltasP3 > 0);
    if (!hayFaltas) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text('Sin faltas registradas en ninguna materia',
                  style: TextStyle(fontSize: 15, color: Colors.green[800], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    final data = materias.map((m) {
      return _MateriaData(m.nombreMateria, (m.faltasP1 + m.faltasP2 + m.faltasP3).toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Faltas por Materia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: -30,
                  labelStyle: const TextStyle(fontSize: 9),
                  labelIntersectAction: AxisLabelIntersectAction.multipleRows,
                  maximumLabelWidth: 80,
                ),
                primaryYAxis: NumericAxis(minimum: 0),
                plotAreaBorderWidth: 0,
                series: <CartesianSeries>[
                  ColumnSeries<_MateriaData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    color: Colors.orange,
                    dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 9)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detalle de materias ───────────────────────────────────────────────────

  Widget _buildListaMaterias(List<Alumno> materias) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalle de Materias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...materias.map((m) => _buildMateriaCard(m)),
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
        title: Text(materia.nombreMateria, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Prof: ${materia.nombreProfesor}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: calFinal != null ? (calFinal >= 7.0 ? Colors.green : Colors.red) : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            calFinal?.toStringAsFixed(1) ?? 'S/C',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                const Text('Calificaciones por Parcial:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildParcialChip('P1', calP1, materia.faltasP1, materia.parcial1, materia.parcialFinal1),
                    _buildParcialChip('P2', calP2, materia.faltasP2, materia.parcial2, materia.parcialFinal2),
                    _buildParcialChip('P3', calP3, materia.faltasP3, materia.parcial3, materia.parcialFinal3),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Faltas: ${materia.faltasP1 + materia.faltasP2 + materia.faltasP3}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildParcialChip(String parcial, double? cal, int faltas, double? original, double? final_) {
    final color = cal != null ? (cal >= 7.0 ? Colors.green : Colors.red) : Colors.grey;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Column(
            children: [
              Text(parcial, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(cal?.toStringAsFixed(1) ?? 'S/C',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              if (original != null)
                Text('orig: ${original.toStringAsFixed(1)}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              if (final_ != null)
                Text('final: ${final_.toStringAsFixed(1)}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Faltas: $faltas', style: const TextStyle(fontSize: 10, color: Colors.orange)),
      ],
    );
  }
}

class _MateriaData {
  final String label;
  final double value;
  _MateriaData(this.label, this.value);
}
