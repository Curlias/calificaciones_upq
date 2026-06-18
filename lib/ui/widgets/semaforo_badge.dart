import 'package:flutter/material.dart';

/// Indicador visual de semáforo para el estado académico de un alumno.
/// estado: 'verde' | 'amarillo' | 'rojo' | 'gris'
class SemaforoBadge extends StatelessWidget {
  final String estado;
  final double size;
  final bool showLabel;

  const SemaforoBadge({
    super.key,
    required this.estado,
    this.size = 14,
    this.showLabel = false,
  });

  static Color colorDeEstado(String estado) {
    switch (estado) {
      case 'verde':
        return Colors.green;
      case 'amarillo':
        return Colors.amber;
      case 'rojo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String labelDeEstado(String estado) {
    switch (estado) {
      case 'verde':
        return 'Aprobado';
      case 'amarillo':
        return 'En riesgo leve';
      case 'rojo':
        return 'En riesgo';
      default:
        return 'Sin calificar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorDeEstado(estado);
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)],
      ),
    );

    if (!showLabel) return dot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 6),
        Text(
          labelDeEstado(estado),
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
