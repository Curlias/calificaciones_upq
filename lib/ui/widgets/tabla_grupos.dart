import 'package:flutter/material.dart';
import '../../models/grupo.dart';

class TablaGrupos extends StatelessWidget {
  final List<Grupo> grupos;
  final int? limite;
  final Function(Grupo)? onGrupoTap;

  const TablaGrupos({
    super.key,
    required this.grupos,
    this.limite,
    this.onGrupoTap,
  });

  @override
  Widget build(BuildContext context) {
    final gruposAMostrar = limite != null ? grupos.take(limite!).toList() : grupos;

    if (gruposAMostrar.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.groups_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay grupos para mostrar',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          // Encabezado de la tabla
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Grupo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Materia',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Tutor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Alumnos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Promedio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Aprobados',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Estado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Filas de datos
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gruposAMostrar.length,
            itemBuilder: (context, index) {
              final grupo = gruposAMostrar[index];
              return _buildFilaGrupo(context, grupo, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilaGrupo(BuildContext context, Grupo grupo, int index) {
    final porcentajeAprobados = grupo.porcentajeAprobados();
    final colorEstado = _getColorEstado(porcentajeAprobados);
    final iconoEstado = _getIconoEstado(porcentajeAprobados);

    return InkWell(
      onTap: onGrupoTap != null ? () => onGrupoTap!(grupo) : null,
      child: Container(
        decoration: BoxDecoration(
          color: index.isEven 
              ? Theme.of(context).colorScheme.surface 
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Grupo
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grupo.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (grupo.alumnos.any((a) => a.esRecursamiento))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Con recursamiento',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
            
            // Materia
            Expanded(
              flex: 4,
              child: Text(
                grupo.nombreMateria,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Tutor
            Expanded(
              flex: 3,
              child: Text(
                grupo.tutor ?? 'No asignado',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Número de alumnos
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    '${grupo.totalAlumnos}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'alumnos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Promedio
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorPromedio(grupo.promedioGeneral).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grupo.promedioGeneral.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getColorPromedio(grupo.promedioGeneral),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Aprobados
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    '${grupo.aprobados()}/${grupo.totalAlumnos}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '(${porcentajeAprobados.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Estado/Indicador
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Icon(
                    iconoEstado,
                    color: colorEstado,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTextoEstado(porcentajeAprobados),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorEstado,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorPromedio(double promedio) {
    if (promedio >= 9.0) return Colors.green;
    if (promedio >= 8.0) return Colors.lightGreen;
    if (promedio >= 7.0) return Colors.orange;
    return Colors.red;
  }

  Color _getColorEstado(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 80) return Colors.lightGreen;
    if (porcentaje >= 70) return Colors.orange;
    if (porcentaje >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getIconoEstado(double porcentaje) {
    if (porcentaje >= 90) return Icons.sentiment_very_satisfied;
    if (porcentaje >= 80) return Icons.sentiment_satisfied;
    if (porcentaje >= 70) return Icons.sentiment_neutral;
    if (porcentaje >= 60) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  String _getTextoEstado(double porcentaje) {
    if (porcentaje >= 90) return 'Excelente';
    if (porcentaje >= 80) return 'Bueno';
    if (porcentaje >= 70) return 'Regular';
    if (porcentaje >= 60) return 'Bajo';
    return 'Crítico';
  }
}