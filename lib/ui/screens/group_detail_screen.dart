import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'student_profile_screen.dart';
import '../../models/grupo.dart';
import '../../models/alumno.dart';
import '../../models/reporte.dart';
import '../../providers/config_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_export_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/alumnos_riesgo_widget.dart';

class GroupDetailScreen extends StatefulWidget {
  final Grupo grupo;

  const GroupDetailScreen({
    super.key,
    required this.grupo,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _ordenamiento = 'calificacion';
  bool _generandoPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, configProvider, child) {
        return Theme(
          data: configProvider.tema,
          child: Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(
              backgroundColor: const Color(0xFF151830),
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grupo ${widget.grupo.nombre}'),
                  Text(
                    '${_getMaterias().length} materia(s)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: _onMenuSelected,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'exportar_pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf),
                          SizedBox(width: 8),
                          Text('Exportar a PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'exportar_alumnos',
                      child: Row(
                        children: [
                          Icon(Icons.people),
                          SizedBox(width: 8),
                          Text('Reportes de Alumnos'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'exportar_excel',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Exportar a Excel'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(icon: Icon(Icons.info), text: 'Resumen'),
                  Tab(icon: Icon(Icons.people), text: 'Alumnos'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
                  Tab(icon: Icon(Icons.analytics), text: 'Análisis'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildResumenTab(),
                _buildAlumnosTab(),
                _buildEstadisticasTab(),
                _buildAnalisisTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumenTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del grupo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Información del Grupo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem('Grupo', widget.grupo.nombre),
                      ),
                      Expanded(
                        child: _buildInfoItem('Total Alumnos', '${widget.grupo.totalAlumnos}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('Materias', '${_getMaterias().length} materia(s)'),
                  const SizedBox(height: 12),
                  ..._buildMateriasList(),
                  const SizedBox(height: 12),
                  _buildInfoItem('Carrera', widget.grupo.carrera),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Estadísticas principales
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Promedio General',
                  widget.grupo.promedioGeneral.toStringAsFixed(2),
                  Icons.grade,
                  _getColorPromedio(widget.grupo.promedioGeneral),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aprobados',
                  '${widget.grupo.aprobados()} / ${widget.grupo.totalAlumnos}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Reprobados',
                  '${widget.grupo.reprobados()}',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Sin Calificar',
                  '${widget.grupo.sinCalificar()}',
                  Icons.help_outline,
                  Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gráfica de aprobados/reprobados
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribución de Aprobación',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildGraficaAprobacion(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumnosTab() {
    final resumen = _buildResumenAlumnos();
    final alumnos = _getAlumnosOrdenados();

    return Column(
      children: [
        // Controles de ordenamiento
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _ordenamiento,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'calificacion', child: Text('Calificación')),
                    DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                    DropdownMenuItem(value: 'matricula', child: Text('Matrícula')),
                    DropdownMenuItem(value: 'faltas', child: Text('Faltas')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _ordenamiento = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${alumnos.length} alumnos',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Lista de alumnos (únicos por matrícula)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: alumnos.length,
            itemBuilder: (context, index) {
              final alumno = alumnos[index];
              final stats = resumen[alumno.matricula]!;
              final cals = stats['cals'] as List<double>;
              final prom = cals.isEmpty
                  ? null
                  : cals.reduce((a, b) => a + b) / cals.length;
              final faltas = stats['faltas'] as int;
              final numMaterias = stats['materias'] as int;
              return _buildTarjetaAlumno(
                alumno, index + 1,
                promedioAgregado: prom,
                faltasAgregadas: faltas,
                numMaterias: numMaterias,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasTab() {
    final estadisticasPorParcial = widget.grupo.estadisticasPorParcial;
    final distribucionGenero = widget.grupo.distribucionPorGenero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas por parcial
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rendimiento por Parcial',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (estadisticasPorParcial.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: _buildGraficaParciales(estadisticasPorParcial),
                    )
                  else
                    const Text('No hay datos suficientes para mostrar estadísticas por parcial'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Distribución por género
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribución por Género',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildGraficaGenero(distribucionGenero),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tabla de estadísticas detalladas
          _buildTablaEstadisticasDetalladas(estadisticasPorParcial),
        ],
      ),
    );
  }

  Widget _buildAnalisisTab() {
    final alumnosConMasFaltas = widget.grupo.alumnosConMasFaltas;
    final alumnosRecursamiento = widget.grupo.alumnosRecursamiento;
    final alumnosEnRiesgo = widget.grupo.alumnosEnRiesgo;
    final tasaReprobacion = widget.grupo.tasaReprobacionPorParcial;
    final correlacion = widget.grupo.correlacionFaltasCalificacion;
    final distribucion = widget.grupo.distribucionRangos;
    final parcialDificil = widget.grupo.parcialMasDificil;
    final pctExtraordinario = widget.grupo.porcentajeExtraordinario;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Alumnos en riesgo ---
          AlumnosRiesgoWidget(
            alumnos: alumnosEnRiesgo,
            onVerPerfil: (matricula) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StudentProfileScreen(matricula: matricula),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Métricas avanzadas ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Métricas Avanzadas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  _buildMetricRow(
                    'Parcial más difícil',
                    parcialDificil > 0 ? 'Parcial $parcialDificil' : 'N/D',
                    Icons.trending_down,
                    Colors.red,
                  ),
                  _buildMetricRow(
                    'Alumnos que necesitan extraordinario',
                    '${widget.grupo.alumnosNecesitanExtraordinario.length} (${pctExtraordinario.toStringAsFixed(1)}%)',
                    Icons.school_outlined,
                    Colors.purple,
                  ),
                  _buildMetricRow(
                    'Correlación faltas↔calificación',
                    correlacion.isNaN ? 'N/D' : '${correlacion.toStringAsFixed(2)} (${_interpretarCorrelacion(correlacion)})',
                    Icons.swap_vert,
                    correlacion.isNaN ? Colors.grey : (correlacion < -0.3 ? Colors.orange : Colors.blue),
                  ),
                  if (tasaReprobacion.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text('Tasa de reprobación por parcial:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...tasaReprobacion.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        SizedBox(
                          width: 80,
                          child: Text('Parcial ${e.key}:', style: const TextStyle(fontSize: 13)),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: e.value / 100,
                            backgroundColor: Colors.grey[200],
                            color: e.value > 50 ? Colors.red : Colors.orange,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.value.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: e.value > 50 ? Colors.red : Colors.orange,
                            )),
                      ]),
                    )),
                  ],
                  if (distribucion.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text('Distribución por rango de calificación:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: distribucion.entries.map((e) => Chip(
                        label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12)),
                        backgroundColor: _colorRango(e.key).withOpacity(0.15),
                        side: BorderSide(color: _colorRango(e.key).withOpacity(0.4)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Análisis de faltas (original) ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Análisis de Asistencia',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Promedio de faltas del grupo: ${widget.grupo.promedioFaltas.toStringAsFixed(1)}'),
                  const SizedBox(height: 16),
                  if (alumnosConMasFaltas.isNotEmpty) ...[
                    const Text(
                      'Alumnos con más faltas:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ...alumnosConMasFaltas.take(5).map((alumno) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.orange,
                        child: Text(
                          '${alumno.totalFaltas}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(alumno.nombre),
                      subtitle: InkWell(
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
                      trailing: Text('${alumno.totalFaltas} faltas'),
                    )),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Análisis de recursamiento
          if (alumnosRecursamiento.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Alumnos en Recursamiento',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Total: ${alumnosRecursamiento.length} alumnos'),
                    const SizedBox(height: 16),
                    ...alumnosRecursamiento.map((alumno) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.refresh, color: Colors.white, size: 16),
                      ),
                      title: Text(alumno.nombre),
                      subtitle: InkWell(
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
                      trailing: Text(
                        alumno.calcularCalificacionFinalCalculada()?.toStringAsFixed(2) ?? 'S/C',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: alumno.aprueba() ? Colors.green : Colors.red,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recomendaciones
          _buildRecomendaciones(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaAlumno(
    Alumno alumno,
    int posicion, {
    double? promedioAgregado,
    int faltasAgregadas = 0,
    int numMaterias = 1,
  }) {
    final calificacion = promedioAgregado ?? alumno.calcularCalificacionFinalCalculada();
    final colorCalificacion = _getColorCalificacion(calificacion);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentProfileScreen(matricula: alumno.matricula),
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Posición
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorCalificacion.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$posicion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorCalificacion,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Información del alumno
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alumno.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Matrícula: ${alumno.matricula}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (numMaterias > 1)
                    Text(
                      '$numMaterias materias',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  if (alumno.esRecursamiento)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Recursamiento',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),

            // Estadísticas
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorCalificacion.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    calificacion?.toStringAsFixed(2) ?? 'S/C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorCalificacion,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$faltasAgregadas faltas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildGraficaAprobacion() {
    final data = [
      EstadoData('Aprobados', widget.grupo.aprobados(), Colors.green),
      EstadoData('Reprobados', widget.grupo.reprobados(), Colors.red),
      if (widget.grupo.sinCalificar() > 0)
        EstadoData('Sin Calificar', widget.grupo.sinCalificar(), Colors.grey),
    ];

    return SfCircularChart(
      series: <CircularSeries>[
        PieSeries<EstadoData, String>(
          dataSource: data,
          xValueMapper: (EstadoData data, _) => data.estado,
          yValueMapper: (EstadoData data, _) => data.cantidad,
          pointColorMapper: (EstadoData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
          ),
        ),
      ],
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),
    );
  }

  Widget _buildGraficaParciales(Map<int, Map<String, double>> estadisticas) {
    final data = estadisticas.entries.map((entry) {
      return ParcialData(
        'Parcial ${entry.key}',
        entry.value['promedio'] ?? 0.0,
        entry.value['porcentajeAprobados'] ?? 0.0,
      );
    }).toList();

    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: const NumericAxis(
        title: AxisTitle(text: 'Promedio'),
        minimum: 0,
        maximum: 10,
      ),
      axes: const <ChartAxis>[
        NumericAxis(
          name: 'porcentajeAxis',
          opposedPosition: true,
          title: AxisTitle(text: 'Porcentaje Aprobados'),
          minimum: 0,
          maximum: 100,
        ),
      ],
      series: <CartesianSeries>[
        ColumnSeries<ParcialData, String>(
          name: 'Promedio',
          dataSource: data,
          xValueMapper: (ParcialData data, _) => data.parcial,
          yValueMapper: (ParcialData data, _) => data.promedio,
          color: Colors.blue,
        ),
        LineSeries<ParcialData, String>(
          name: 'Porcentaje Aprobados',
          dataSource: data,
          xValueMapper: (ParcialData data, _) => data.parcial,
          yValueMapper: (ParcialData data, _) => data.porcentajeAprobados,
          yAxisName: 'porcentajeAxis',
          color: Colors.green,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
      legend: const Legend(isVisible: true),
    );
  }

  Widget _buildGraficaGenero(Map<String, int> distribucion) {
    final data = distribucion.entries.map((entry) {
      return GeneroData(
        entry.key == 'M' ? 'Masculino' : 'Femenino',
        entry.value,
        entry.key == 'M' ? Colors.blue : Colors.pink,
      );
    }).toList();

    return SfCircularChart(
      series: <CircularSeries>[
        DoughnutSeries<GeneroData, String>(
          dataSource: data,
          xValueMapper: (GeneroData data, _) => data.genero,
          yValueMapper: (GeneroData data, _) => data.cantidad,
          pointColorMapper: (GeneroData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          innerRadius: '60%',
        ),
      ],
      legend: const Legend(isVisible: true),
    );
  }

  Widget _buildTablaEstadisticasDetalladas(Map<int, Map<String, double>> estadisticas) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas Detalladas por Parcial',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Parcial', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Promedio', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Aprobados', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Reprobados', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('% Aprobación', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...estadisticas.entries.map((entry) {
                  final parcial = entry.key;
                  final stats = entry.value;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Parcial $parcial'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(stats['promedio']?.toStringAsFixed(2) ?? '-'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(stats['aprobados']?.toInt().toString() ?? '-'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(stats['reprobados']?.toInt().toString() ?? '-'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('${stats['porcentajeAprobados']?.toStringAsFixed(1) ?? '-'}%'),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendaciones() {
    final recomendaciones = <String>[];
    
    if (widget.grupo.porcentajeAprobados() < 70) {
      recomendaciones.add('El porcentaje de aprobación es bajo. Considere revisar la metodología de enseñanza.');
    }
    
    if (widget.grupo.promedioFaltas > 3) {
      recomendaciones.add('El promedio de faltas es alto. Implemente estrategias para mejorar la asistencia.');
    }
    
    if (widget.grupo.alumnosRecursamiento.isNotEmpty) {
      recomendaciones.add('Hay alumnos en recursamiento. Brinde apoyo adicional a estos estudiantes.');
    }
    
    if (widget.grupo.promedioGeneral < 7.5) {
      recomendaciones.add('El promedio general está por debajo del esperado. Considere tutorías adicionales.');
    }

    if (recomendaciones.isEmpty) {
      recomendaciones.add('El grupo muestra un buen rendimiento general. Continúe con las estrategias actuales.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Recomendaciones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recomendaciones.map((recomendacion) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(recomendacion)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Construye un resumen por alumno: promedio y faltas acumuladas de TODAS sus materias.
  Map<String, Map<String, dynamic>> _buildResumenAlumnos() {
    final Map<String, Map<String, dynamic>> res = {};
    for (final a in widget.grupo.alumnos) {
      if (!res.containsKey(a.matricula)) {
        res[a.matricula] = {
          'alumno': a,
          'cals': <double>[],
          'faltas': 0,
          'materias': 0,
        };
      }
      final cal = a.calcularCalificacionFinalCalculada();
      if (cal != null) (res[a.matricula]!['cals'] as List<double>).add(cal);
      res[a.matricula]!['faltas'] = (res[a.matricula]!['faltas'] as int) + a.totalFaltas;
      res[a.matricula]!['materias'] = (res[a.matricula]!['materias'] as int) + 1;
    }
    return res;
  }

  List<Alumno> _getAlumnosOrdenados() {
    final resumen = _buildResumenAlumnos();
    // Un Alumno representante por matrícula (primero en aparecer)
    final alumnos = resumen.values.map((r) => r['alumno'] as Alumno).toList();

    double _prom(String matricula) {
      final cals = resumen[matricula]!['cals'] as List<double>;
      return cals.isEmpty ? 0.0 : cals.reduce((a, b) => a + b) / cals.length;
    }

    switch (_ordenamiento) {
      case 'calificacion':
        alumnos.sort((a, b) => _prom(b.matricula).compareTo(_prom(a.matricula)));
        break;
      case 'nombre':
        alumnos.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case 'matricula':
        alumnos.sort((a, b) => a.matricula.compareTo(b.matricula));
        break;
      case 'faltas':
        alumnos.sort((a, b) {
          final fa = resumen[a.matricula]!['faltas'] as int;
          final fb = resumen[b.matricula]!['faltas'] as int;
          return fb.compareTo(fa);
        });
        break;
    }

    return alumnos;
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  String _interpretarCorrelacion(double r) {
    if (r < -0.7) return 'alta negativa';
    if (r < -0.3) return 'moderada negativa';
    if (r < 0.3) return 'baja';
    if (r < 0.7) return 'moderada positiva';
    return 'alta positiva';
  }

  Color _colorRango(String rango) {
    switch (rango) {
      case '9–10': return Colors.green;
      case '8–9': return Colors.lightGreen;
      case '7–8': return Colors.orange;
      case '5–7': return Colors.deepOrange;
      case '0–5': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getColorPromedio(double promedio) {
    if (promedio >= 9.0) return Colors.green;
    if (promedio >= 8.0) return Colors.lightGreen;
    if (promedio >= 7.0) return Colors.orange;
    return Colors.red;
  }

  Color _getColorCalificacion(double? calificacion) {
    if (calificacion == null) return Colors.grey;
    if (calificacion >= 9.0) return Colors.green;
    if (calificacion >= 8.0) return Colors.lightGreen;
    if (calificacion >= 7.0) return Colors.orange;
    return Colors.red;
  }

  void _onMenuSelected(String value) async {
    switch (value) {
      case 'exportar_pdf':
        await _exportarGrupoPdf();
        break;
      case 'exportar_alumnos':
        await _exportarAlumnosPdf();
        break;
      case 'exportar_excel':
        await _exportarExcel();
        break;
    }
  }

  Future<void> _exportarExcel() async {
    try {
      final nombreArchivo =
          'grupo_${widget.grupo.nombre}_${widget.grupo.nombreMateria.replaceAll(' ', '_')}';
      final path = await ExcelExportService.exportarAlumnos(
        alumnos: widget.grupo.alumnos,
        nombreArchivo: nombreArchivo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? 'Excel guardado en: $path' : 'Error al exportar Excel'),
            backgroundColor: path != null ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportarGrupoPdf() async {
    setState(() {
      _generandoPdf = true;
    });

    try {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      final reporte = ReporteGrupo(
        grupo: widget.grupo,
        fechaGeneracion: DateTime.now(),
      );

      final pdfBytes = await PdfService.generarReporteGrupo(
        reporte: reporte,
        logoPath: configProvider.logoPath,
        nombreInstitucion: configProvider.nombreInstitucion,
        incluirFirma: configProvider.incluirFirmaEnReportes,
        textoFirma: configProvider.textoFirma,
      );

      final nombreArchivo = 'reporte_grupo_${widget.grupo.nombre}_${widget.grupo.nombreMateria.replaceAll(' ', '_')}.pdf';
      await PdfService.guardarPdf(pdfBytes, nombreArchivo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte del grupo generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _generandoPdf = false;
      });
    }
  }

  Future<void> _exportarAlumnosPdf() async {
    setState(() {
      _generandoPdf = true;
    });

    try {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      
      for (final alumno in widget.grupo.alumnos) {
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
        await PdfService.guardarPdf(pdfBytes, nombreArchivo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.grupo.alumnos.length} reportes individuales generados'),
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
        _generandoPdf = false;
      });
    }
  }

  List<String> _getMaterias() {
    return widget.grupo.alumnos
        .map((a) => a.nombreMateria)
        .toSet()
        .toList()
      ..sort();
  }

  List<Widget> _buildMateriasList() {
    final materias = _getMaterias();
    return [
      const Text(
        'Materias del grupo:',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: materias.map((materia) {
          final alumnosMateria = widget.grupo.alumnos
              .where((a) => a.nombreMateria == materia)
              .toList();
          return Chip(
            label: Text(
              '$materia (${alumnosMateria.length})',
              style: const TextStyle(fontSize: 11),
            ),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    ];
  }
}

// Clases auxiliares para las gráficas
class EstadoData {
  final String estado;
  final int cantidad;
  final Color color;

  EstadoData(this.estado, this.cantidad, this.color);
}

class ParcialData {
  final String parcial;
  final double promedio;
  final double porcentajeAprobados;

  ParcialData(this.parcial, this.promedio, this.porcentajeAprobados);
}

class GeneroData {
  final String genero;
  final int cantidad;
  final Color color;

  GeneroData(this.genero, this.cantidad, this.color);
}