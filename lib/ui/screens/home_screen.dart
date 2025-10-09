import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/data_provider.dart';
import '../../providers/config_provider.dart';
import '../widgets/estadisticas_card.dart';
import '../widgets/grafica_distribucion.dart';
import '../widgets/tabla_grupos.dart';
import 'import_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'group_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataProvider, ConfigProvider>(
      builder: (context, dataProvider, configProvider, child) {
        return Theme(
          data: configProvider.tema,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sistema de Calificaciones UPQ'),
              elevation: 2,
              actions: [
                if (dataProvider.tieneDatos) ...[
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refrescarDatos,
                    tooltip: 'Refrescar datos',
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _mostrarBusqueda,
                    tooltip: 'Buscar',
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  onPressed: _importarArchivo,
                  tooltip: 'Importar Excel',
                ),
              ],
            ),
            drawer: _buildDrawer(context, dataProvider),
            body: _buildBody(dataProvider),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, DataProvider dataProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<ConfigProvider>(
            builder: (context, configProvider, child) {
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: configProvider.colorPrimario,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      configProvider.nombreInstitucion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sistema de Calificaciones',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (dataProvider.tieneDatos)
                      Text(
                        'Última actualización:\n${_formatFecha(dataProvider.fechaUltimaCarga)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          if (dataProvider.tieneDatos) ...[
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Grupos'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reportes'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Exportar Todo'),
              onTap: _exportarTodo,
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Importar Excel'),
            onTap: _importarArchivo,
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          if (dataProvider.tieneDatos)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Información del Archivo'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${dataProvider.totalAlumnos} registros'),
                  Text('${dataProvider.totalGrupos} grupos'),
                  Text('${dataProvider.totalMaterias} materias'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(DataProvider dataProvider) {
    if (dataProvider.estaCargando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos...'),
          ],
        ),
      );
    }

    if (dataProvider.tieneError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              dataProvider.mensajeError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _importarArchivo,
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      );
    }

    if (!dataProvider.tieneDatos) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Bienvenido al Sistema de Calificaciones',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Para comenzar, importa un archivo Excel con los datos de calificaciones',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _importarArchivo,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar Archivo Excel'),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(dataProvider);
      case 1:
        return _buildGrupos(dataProvider);
      case 2:
        return const ReportScreen();
      default:
        return _buildDashboard(dataProvider);
    }
  }

  Widget _buildDashboard(DataProvider dataProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard General',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          
          // Tarjetas de estadísticas
          EstadisticasCard(
            totalAlumnos: dataProvider.totalAlumnos,
            totalGrupos: dataProvider.totalGrupos,
            totalMaterias: dataProvider.totalMaterias,
            promedioGeneral: dataProvider.promedioGeneral,
            totalAprobados: dataProvider.totalAprobados,
            totalReprobados: dataProvider.totalReprobados,
            totalSinCalificar: dataProvider.totalSinCalificar,
          ),
          
          const SizedBox(height: 24),
          
          // Gráficas
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distribución de Calificaciones',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: GraficaDistribucion(
                            alumnos: dataProvider.alumnos,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estadísticas por Carrera',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildEstadisticasCarrera(dataProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Tabla de grupos con mejor rendimiento
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grupos con Mejor Rendimiento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TablaGrupos(
                    grupos: dataProvider.grupos..sort((a, b) => b.promedioGeneral.compareTo(a.promedioGeneral)),
                    limite: 10,
                    onGrupoTap: (grupo) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailScreen(grupo: grupo),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupos(DataProvider dataProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Todos los Grupos',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: _mostrarFiltros,
                icon: const Icon(Icons.filter_list),
                label: const Text('Filtros'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TablaGrupos(
            grupos: dataProvider.gruposFiltrados,
            onGrupoTap: (grupo) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailScreen(grupo: grupo),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCarrera(DataProvider dataProvider) {
    final estadisticas = dataProvider.estadisticasPorCarrera;
    
    return ListView.builder(
      itemCount: estadisticas.length,
      itemBuilder: (context, index) {
        final carrera = estadisticas.keys.elementAt(index);
        final stats = estadisticas[carrera]!;
        
        return ListTile(
          title: Text(
            carrera,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alumnos: ${stats['totalAlumnos']}'),
              Text('Promedio: ${stats['promedio'].toStringAsFixed(2)}'),
              Text('Aprobados: ${stats['porcentajeAprobados'].toStringAsFixed(1)}%'),
            ],
          ),
          trailing: CircleAvatar(
            backgroundColor: stats['porcentajeAprobados'] >= 70 ? Colors.green : Colors.orange,
            child: Text(
              '${stats['porcentajeAprobados'].toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  void _importarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImportScreen(filePath: filePath),
            ),
          );
        }
      }
    }
  }

  void _refrescarDatos() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.refrescarDatos();
  }

  void _mostrarBusqueda() {
    showSearch(
      context: context,
      delegate: AlumnoSearchDelegate(),
    );
  }

  void _mostrarFiltros() {
    // TODO: Implementar panel de filtros
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panel de filtros en desarrollo')),
    );
  }

  void _exportarTodo() {
    // TODO: Implementar exportación masiva
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportación masiva en desarrollo')),
    );
  }

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

class AlumnoSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (query.isEmpty) {
          return const Center(
            child: Text('Ingrese un término de búsqueda'),
          );
        }

        dataProvider.buscarAlumnos(query);
        final alumnos = dataProvider.alumnosFiltrados;

        if (alumnos.isEmpty) {
          return const Center(
            child: Text('No se encontraron resultados'),
          );
        }

        return ListView.builder(
          itemCount: alumnos.length,
          itemBuilder: (context, index) {
            final alumno = alumnos[index];
            return ListTile(
              title: Text(alumno.nombre),
              subtitle: Text('${alumno.matricula} - ${alumno.nombreMateria}'),
              trailing: Text(
                alumno.calcularCalificacionFinalCalculada()?.toStringAsFixed(2) ?? 'S/C',
                style: TextStyle(
                  color: alumno.aprueba() ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // TODO: Navegar a detalle del alumno
                close(context, alumno.nombre);
              },
            );
          },
        );
      },
    );
  }
}