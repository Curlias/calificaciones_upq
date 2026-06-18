import 'package:flutter/material.dart';
import '../../models/alumno.dart';
import 'semaforo_badge.dart';

/// Tarjeta expandible que lista los alumnos en riesgo con métricas clave.
class AlumnosRiesgoWidget extends StatelessWidget {
  final List<Alumno> alumnos;
  final void Function(String matricula)? onVerPerfil;

  const AlumnosRiesgoWidget({
    super.key,
    required this.alumnos,
    this.onVerPerfil,
  });

  @override
  Widget build(BuildContext context) {
    if (alumnos.isEmpty) {
      return Card(
        color: Colors.green.withOpacity(0.08),
        child: const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Sin alumnos en riesgo', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Todos los alumnos tienen buen rendimiento'),
        ),
      );
    }

    return Card(
      color: Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        title: Text(
          'Alumnos en riesgo (${alumnos.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        subtitle: const Text('2+ faltas o 2+ parciales reprobados'),
        children: alumnos.map((a) => _buildRow(context, a)).toList(),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Alumno a) {
    final cal = a.calcularCalificacionFinalCalculada();
    return ListTile(
      dense: true,
      leading: SemaforoBadge(estado: a.estadoSemaforo, size: 12),
      title: Text(a.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text('${a.grupo} · ${a.nombreMateria}', style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(
            '${a.totalFaltas} faltas',
            a.totalFaltas >= 2 ? Colors.orange : Colors.grey,
          ),
          const SizedBox(width: 6),
          _chip(
            cal != null ? cal.toStringAsFixed(1) : 'S/C',
            cal != null && cal < 7.0 ? Colors.red : Colors.grey,
          ),
          if (onVerPerfil != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.person, size: 18),
              tooltip: 'Ver perfil',
              onPressed: () => onVerPerfil!(a.matricula),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
