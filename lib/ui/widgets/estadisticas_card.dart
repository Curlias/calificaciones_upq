import 'package:flutter/material.dart';

class EstadisticasCard extends StatelessWidget {
  final int totalAlumnos;
  final int totalGrupos;
  final int totalMaterias;
  final double promedioGeneral;
  final int totalAprobados;
  final int totalReprobados;
  final int totalSinCalificar;

  const EstadisticasCard({
    super.key,
    required this.totalAlumnos,
    required this.totalGrupos,
    required this.totalMaterias,
    required this.promedioGeneral,
    required this.totalAprobados,
    required this.totalReprobados,
    required this.totalSinCalificar,
  });

  @override
  Widget build(BuildContext context) {
    final porcentajeAprobados = totalAlumnos > 0 
        ? (totalAprobados / (totalAprobados + totalReprobados)) * 100 
        : 0.0;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          context,
          'Total Alumnos',
          totalAlumnos.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Total Grupos',
          totalGrupos.toString(),
          Icons.groups,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Materias',
          totalMaterias.toString(),
          Icons.book,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Promedio General',
          promedioGeneral.toStringAsFixed(2),
          Icons.grade,
          _getColorForGrade(promedioGeneral),
        ),
        _buildStatCard(
          context,
          'Aprobados',
          '$totalAprobados\n(${porcentajeAprobados.toStringAsFixed(1)}%)',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Reprobados',
          totalReprobados.toString(),
          Icons.cancel,
          Colors.red,
        ),
        _buildStatCard(
          context,
          'Sin Calificar',
          totalSinCalificar.toString(),
          Icons.help_outline,
          Colors.grey,
        ),
        _buildStatCard(
          context,
          'Índice de Aprobación',
          '${porcentajeAprobados.toStringAsFixed(1)}%',
          Icons.trending_up,
          _getColorForPercentage(porcentajeAprobados),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForGrade(double grade) {
    if (grade >= 9.0) return Colors.green;
    if (grade >= 8.0) return Colors.lightGreen;
    if (grade >= 7.0) return Colors.orange;
    return Colors.red;
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }
}