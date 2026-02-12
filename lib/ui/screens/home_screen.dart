import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/data_provider.dart';
import '../../providers/config_provider.dart';
import '../../services/storage_service.dart';
import '../../models/grupo.dart';
import '../widgets/estadisticas_card.dart';
import '../widgets/grafica_distribucion.dart';
import '../widgets/tabla_grupos.dart';
import '../widgets/vista_generaciones.dart';
import 'import_screen.dart';
import 'import_config_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'group_detail_screen.dart';
import 'student_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _informesGuardados = {};
  List<Grupo> _gruposSeleccionados = [];
  String _filtroCarrera = '';
  String _filtroMateria = '';
  String _busquedaGrupo = '';

  @override
  void initState() {
    super.initState();
    _cargarInformesGuardados();
  }

  Future<void> _cargarInformesGuardados() async {
    final informes = await StorageService.getSavedReports();
    setState(() {
      _informesGuardados = informes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataProvider, ConfigProvider>(
      builder: (context, dataProvider, configProvider, child) {
        return Theme(
          data: configProvider.tema,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Text('Sistema de Calificaciones UPQ'),
                  if (dataProvider.tieneDatos && _informesGuardados.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const Text('|', style: TextStyle(color: Colors.white54)),
                    const SizedBox(width: 8),
                    _buildInformeSelector(dataProvider),
                  ],
                ],
              ),
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
      child: Column(
        children: [
          Expanded(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (configProvider.logoPath != null)
                                Image.asset(
                                  configProvider.logoPath!,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                configProvider.nombreInstitucion,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Sistema de Calificaciones',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          if (dataProvider.tieneDatos)
                            Text(
                              'Última actualización:\n${_formatFecha(dataProvider.fechaUltimaCarga)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                    leading: const Icon(Icons.school),
                    title: const Text('Generaciones'),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups),
                    title: const Text('Grupos'),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      setState(() => _selectedIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assessment),
                    title: const Text('Reportes'),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      setState(() => _selectedIndex = 3);
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
          ),
          // Footer del drawer
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Versión 1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Desarrollado para la',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'Universidad Politécnica de Querétaro',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Potenciado con la tecnología de ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse('https://veldrion.com');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: const Text(
                        'veldrion.com',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
      return _buildWelcomeScreen();
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(dataProvider);
      case 1:
        return const VistaGeneraciones();
      case 2:
        return _buildGrupos(dataProvider);
      case 3:
        return const ReportScreen();
      default:
        return _buildDashboard(dataProvider);
    }
  }

  Widget _buildWelcomeScreen() {
    return FutureBuilder<Map<String, dynamic>>(
      future: StorageService.getSavedReports(),
      builder: (context, snapshot) {
        final savedReports = snapshot.data ?? {};
        final hasSavedReports = savedReports.isNotEmpty;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Consumer<ConfigProvider>(
                    builder: (context, configProvider, child) {
                      if (configProvider.logoPath != null) {
                        return Image.asset(
                          configProvider.logoPath!,
                          height: 120,
                          fit: BoxFit.contain,
                        );
                      }
                      return const Icon(Icons.upload_file, size: 64, color: Colors.grey);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenido al Sistema de Calificaciones',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Para comenzar, importa un archivo Excel con los datos de calificaciones',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _importarArchivo,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar Archivo Excel'),
                  ),
                  if (hasSavedReports) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Informes Guardados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: savedReports.length,
                        itemBuilder: (context, index) {
                          final reportId = savedReports.keys.elementAt(index);
                          final reportInfo = savedReports[reportId];
                          return _buildReportCard(reportId, reportInfo);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(String reportId, Map<String, dynamic> reportInfo) {
    final reportName = reportInfo['name'] ?? 'Sin nombre';
    final alumnosCount = reportInfo['alumnosCount'] ?? 0;
    final gruposCount = reportInfo['gruposCount'] ?? 0;
    final createdAt = DateTime.tryParse(reportInfo['createdAt'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.description, color: Colors.white),
        ),
        title: Text(reportName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$alumnosCount estudiantes, $gruposCount grupos'),
            Text(
              _formatFecha(createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'load') {
              final dataProvider = Provider.of<DataProvider>(context, listen: false);
              final success = await dataProvider.cargarInformeGuardado(reportId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe cargado exitosamente')),
                );
              }
            } else if (value == 'rename') {
              _mostrarDialogoRenombrar(reportId, reportName);
            } else if (value == 'delete') {
              _confirmarEliminarInforme(reportId, reportName);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'load',
              child: Row(
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 8),
                  Text('Cargar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Renombrar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () async {
          final dataProvider = Provider.of<DataProvider>(context, listen: false);
          final success = await dataProvider.cargarInformeGuardado(reportId);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Informe cargado exitosamente')),
            );
          }
        },
      ),
    );
  }

  void _mostrarDialogoRenombrar(String reportId, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar Informe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await StorageService.renameReport(
                  reportId,
                  controller.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    setState(() {}); // Actualizar la lista
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe renombrado')),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarInforme(String reportId, String reportName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Informe'),
        content: Text('¿Estás seguro de eliminar "$reportName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await StorageService.deleteReport(reportId);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  setState(() {}); // Actualizar la lista
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe eliminado')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
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
          
          // Resumen de Generaciones
          if (dataProvider.generacionesDisponibles.isNotEmpty)
            _buildResumenGeneraciones(dataProvider),
          
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
    // Aplicar filtros
    var gruposFiltrados = dataProvider.grupos.where((grupo) {
      bool cumpleFiltros = true;
      
      if (_busquedaGrupo.isNotEmpty) {
        cumpleFiltros = cumpleFiltros && 
          (grupo.nombre.toLowerCase().contains(_busquedaGrupo.toLowerCase()) ||
           grupo.nombreMateria.toLowerCase().contains(_busquedaGrupo.toLowerCase()));
      }
      
      if (_filtroCarrera.isNotEmpty) {
        cumpleFiltros = cumpleFiltros && grupo.carrera == _filtroCarrera;
      }
      
      if (_filtroMateria.isNotEmpty) {
        cumpleFiltros = cumpleFiltros && grupo.nombreMateria == _filtroMateria;
      }
      
      return cumpleFiltros;
    }).toList();

    return Column(
      children: [
        // Barra de búsqueda y controles
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              // Búsqueda
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar grupo o materia...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _busquedaGrupo.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _busquedaGrupo = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _busquedaGrupo = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Filtros y acciones
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarFiltrosAvanzados(dataProvider),
                      icon: const Icon(Icons.filter_alt),
                      label: Text(
                        'Filtros' + 
                        (_filtroCarrera.isNotEmpty || _filtroMateria.isNotEmpty 
                          ? ' (${(_filtroCarrera.isNotEmpty ? 1 : 0) + (_filtroMateria.isNotEmpty ? 1 : 0)})' 
                          : ''),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_filtroCarrera.isNotEmpty || _filtroMateria.isNotEmpty)
                            ? Colors.orange
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _gruposSeleccionados.length >= 2
                          ? () => _compararGrupos()
                          : null,
                      icon: const Icon(Icons.compare_arrows),
                      label: Text('Comparar (${_gruposSeleccionados.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gruposSeleccionados.length >= 2
                            ? Colors.green
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista de grupos
        Expanded(
          child: gruposFiltrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron grupos',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      if (_busquedaGrupo.isNotEmpty || _filtroCarrera.isNotEmpty || _filtroMateria.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _busquedaGrupo = '';
                              _filtroCarrera = '';
                              _filtroMateria = '';
                            });
                          },
                          child: const Text('Limpiar filtros'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gruposFiltrados.length,
                  itemBuilder: (context, index) {
                    final grupo = gruposFiltrados[index];
                    final isSelected = _gruposSeleccionados.any(
                      (g) => g.nombre == grupo.nombre && g.materia == grupo.materia,
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 1,
                      color: isSelected ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (_gruposSeleccionados.length < 4) {
                                  _gruposSeleccionados.add(grupo);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Máximo 4 grupos para comparar'),
                                    ),
                                  );
                                }
                              } else {
                                _gruposSeleccionados.removeWhere(
                                  (g) => g.nombre == grupo.nombre && g.materia == grupo.materia,
                                );
                              }
                            });
                          },
                        ),
                        title: Text(
                          grupo.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(grupo.nombreMateria),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${grupo.alumnos.length} alumnos',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  grupo.promedioGeneral.toStringAsFixed(2),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupDetailScreen(grupo: grupo),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
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
          final navigator = Navigator.of(context);
          await navigator.push(
            MaterialPageRoute(
              builder: (context) => ImportConfigScreen(filePath: filePath),
            ),
          );
          // Recargar informes después de importar
          await _cargarInformesGuardados();
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

  void _mostrarFiltrosAvanzados(DataProvider dataProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final carreras = dataProvider.carreras;
            final materias = dataProvider.materias;

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros Avanzados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Filtro por Carrera
                  const Text(
                    'Carrera',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _filtroCarrera.isEmpty ? null : _filtroCarrera,
                    decoration: const InputDecoration(
                      hintText: 'Todas las carreras',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas las carreras'),
                      ),
                      ...carreras.map((carrera) => DropdownMenuItem<String>(
                        value: carrera,
                        child: Text(carrera),
                      )),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _filtroCarrera = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Filtro por Materia
                  const Text(
                    'Materia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _filtroMateria.isEmpty ? null : _filtroMateria,
                    decoration: const InputDecoration(
                      hintText: 'Todas las materias',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas las materias'),
                      ),
                      ...materias.map((materia) => DropdownMenuItem<String>(
                        value: materia,
                        child: Text(materia),
                      )),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _filtroMateria = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _filtroCarrera = '';
                              _filtroMateria = '';
                            });
                            setState(() {
                              _filtroCarrera = '';
                              _filtroMateria = '';
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Actualizar la vista principal
                            Navigator.pop(context);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _compararGrupos() {
    if (_gruposSeleccionados.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos 2 grupos')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comparación de Grupos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabla comparativa
                      Table(
                        border: TableBorder.all(color: Colors.grey[300]!),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        children: [
                          // Encabezado
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[200]),
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Métrica',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._gruposSeleccionados.map((grupo) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  grupo.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                          // Materia
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Materia'),
                              ),
                              ..._gruposSeleccionados.map((grupo) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  grupo.nombreMateria,
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                          // Promedio
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Promedio'),
                              ),
                              ..._gruposSeleccionados.map((grupo) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  grupo.promedioGeneral.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: grupo.promedioGeneral >= 8 ? Colors.green : Colors.orange,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                          // Total Alumnos
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Total Alumnos'),
                              ),
                              ..._gruposSeleccionados.map((grupo) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${grupo.alumnos.length}',
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                          // Aprobados
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Aprobados'),
                              ),
                              ..._gruposSeleccionados.map((grupo) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${grupo.aprobados()} (${grupo.porcentajeAprobados().toStringAsFixed(1)}%)',
                                  style: const TextStyle(color: Colors.green),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                          // Reprobados
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Reprobados'),
                              ),
                              ..._gruposSeleccionados.map((grupo) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${grupo.reprobados()} (${grupo.porcentajeReprobados().toStringAsFixed(1)}%)',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                          // Índice de Aprobación
                          TableRow(
                            decoration: BoxDecoration(color: Colors.blue[50]),
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Índice de Aprobación',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._gruposSeleccionados.map((grupo) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${(grupo.porcentajeAprobados() / 100 * 10).toStringAsFixed(1)}/10',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Análisis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._generarAnalisisComparativo(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _generarAnalisisComparativo() {
    final promedios = _gruposSeleccionados.map((g) => g.promedioGeneral).toList();
    final mejorGrupo = _gruposSeleccionados[promedios.indexOf(promedios.reduce((a, b) => a > b ? a : b))];
    final peorGrupo = _gruposSeleccionados[promedios.indexOf(promedios.reduce((a, b) => a < b ? a : b))];
    
    return [
      _buildAnalisisCard(
        Icons.emoji_events,
        'Mejor Desempeño',
        '${mejorGrupo.nombre} con promedio de ${mejorGrupo.promedioGeneral.toStringAsFixed(2)}',
        Colors.green,
      ),
      if (mejorGrupo.nombre != peorGrupo.nombre)
        _buildAnalisisCard(
          Icons.trending_down,
          'Requiere Atención',
          '${peorGrupo.nombre} con promedio de ${peorGrupo.promedioGeneral.toStringAsFixed(2)}',
          Colors.orange,
        ),
      _buildAnalisisCard(
        Icons.calculate,
        'Promedio General',
        (promedios.reduce((a, b) => a + b) / promedios.length).toStringAsFixed(2),
        Colors.blue,
      ),
    ];
  }

  Widget _buildAnalisisCard(IconData icon, String titulo, String valor, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(titulo),
        subtitle: Text(valor),
      ),
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

  Widget _buildInformeSelector(DataProvider dataProvider) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      tooltip: 'Cambiar informe',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                dataProvider.informeActualNombre.isNotEmpty
                    ? dataProvider.informeActualNombre
                    : 'Seleccionar informe',
                style: const TextStyle(fontSize: 13, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        // Ordenar informes por fecha (más reciente primero)
        final informesList = _informesGuardados.entries.toList();
        informesList.sort((a, b) {
          final dateA = DateTime.parse(a.value['createdAt']);
          final dateB = DateTime.parse(b.value['createdAt']);
          return dateB.compareTo(dateA);
        });

        for (final entry in informesList) {
          final reportId = entry.key;
          final reportData = entry.value;
          final isActual = reportId == dataProvider.informeActualId;
          
          items.add(
            PopupMenuItem<String>(
              value: reportId,
              child: Row(
                children: [
                  Icon(
                    isActual ? Icons.check_circle : Icons.folder,
                    size: 18,
                    color: isActual ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reportData['name'],
                          style: TextStyle(
                            fontWeight: isActual ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '${reportData['alumnosCount']} registros • ${_formatFechaCorta(DateTime.parse(reportData['createdAt']))}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (items.isEmpty) {
          items.add(
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('No hay informes guardados'),
            ),
          );
        }

        return items;
      },
      onSelected: (reportId) async {
        if (reportId != dataProvider.informeActualId) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Cambiando informe...')),
          );

          final success = await dataProvider.cargarInformeGuardado(reportId);
          
          if (success) {
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Informe cargado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            await _cargarInformesGuardados();
          } else {
            scaffoldMessenger.hideCurrentSnackBar();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error al cargar informe: ${dataProvider.mensajeError}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  String _formatFechaCorta(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Widget _buildResumenGeneraciones(DataProvider dataProvider) {
    final generaciones = dataProvider.generacionesDisponibles;
    
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
                  'Resumen por Generaciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.school),
                  label: const Text('Ver Todas'),
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: generaciones.map((gen) {
                  final stats = dataProvider.estadisticasPorGeneracion(gen);
                  return Card(
                    margin: const EdgeInsets.only(right: 12),
                    color: Colors.blue[50],
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Gen. $gen',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildStatRow('Alumnos', '${stats['totalAlumnos']}', Icons.people),
                          _buildStatRow('Grupos', '${stats['grupos']}', Icons.group_work),
                          _buildStatRow('Promedio', '${stats['promedioGeneral'].toStringAsFixed(2)}', Icons.trending_up),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${stats['aprobados']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const Text('Apr.', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${stats['reprobados']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const Text('Rep.', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class AlumnoSearchDelegate extends SearchDelegate<String> {
  String _filtroEstado = 'todos'; // todos, aprobados, reprobados
  String _filtroCarrera = '';
  String _filtroMateria = '';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: 'Filtros',
        onPressed: () => _mostrarFiltros(context),
      ),
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

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dataProvider = Provider.of<DataProvider>(context, listen: false);
            final carreras = dataProvider.carreras;
            final materias = dataProvider.materias;

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros de Búsqueda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Estado académico
                  const Text('Estado Académico', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'todos', label: Text('Todos'), icon: Icon(Icons.people)),
                      ButtonSegment(value: 'aprobados', label: Text('Aprobados'), icon: Icon(Icons.check_circle)),
                      ButtonSegment(value: 'reprobados', label: Text('Reprobados'), icon: Icon(Icons.cancel)),
                    ],
                    selected: {_filtroEstado},
                    onSelectionChanged: (Set<String> newSelection) {
                      setModalState(() {
                        _filtroEstado = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Carrera
                  const Text('Carrera', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _filtroCarrera.isEmpty ? null : _filtroCarrera,
                    decoration: const InputDecoration(
                      hintText: 'Todas las carreras',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Todas las carreras')),
                      ...carreras.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _filtroCarrera = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Materia
                  const Text('Materia', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _filtroMateria.isEmpty ? null : _filtroMateria,
                    decoration: const InputDecoration(
                      hintText: 'Todas las materias',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Todas las materias')),
                      ...materias.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _filtroMateria = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _filtroEstado = 'todos';
                              _filtroCarrera = '';
                              _filtroMateria = '';
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            showResults(context);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (query.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Ingrese un término de búsqueda'),
                const SizedBox(height: 8),
                Text(
                  'Busca por nombre, matrícula o materia',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Buscar alumnos
        dataProvider.buscarAlumnos(query);
        var alumnos = dataProvider.alumnosFiltrados;

        // Aplicar filtros adicionales
        if (_filtroEstado == 'aprobados') {
          alumnos = alumnos.where((a) => a.aprueba()).toList();
        } else if (_filtroEstado == 'reprobados') {
          alumnos = alumnos.where((a) {
            final cal = a.calcularCalificacionFinalCalculada();
            return cal != null && cal < 7.0;
          }).toList();
        }

        if (_filtroCarrera.isNotEmpty) {
          alumnos = alumnos.where((a) => a.carrera == _filtroCarrera).toList();
        }

        if (_filtroMateria.isNotEmpty) {
          alumnos = alumnos.where((a) => a.nombreMateria == _filtroMateria).toList();
        }

        if (alumnos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No se encontraron resultados'),
                const SizedBox(height: 8),
                if (_filtroEstado != 'todos' || _filtroCarrera.isNotEmpty || _filtroMateria.isNotEmpty)
                  TextButton(
                    onPressed: () => _mostrarFiltros(context),
                    child: const Text('Modificar filtros'),
                  ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Indicador de filtros activos
            if (_filtroEstado != 'todos' || _filtroCarrera.isNotEmpty || _filtroMateria.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtros activos: ${_construirTextoFiltros()}',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _filtroEstado = 'todos';
                        _filtroCarrera = '';
                        _filtroMateria = '';
                        showResults(context);
                      },
                      child: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            // Lista de resultados
            Expanded(
              child: ListView.builder(
                itemCount: alumnos.length,
                itemBuilder: (context, index) {
                  final alumno = alumnos[index];
                  final calificacion = alumno.calcularCalificacionFinalCalculada();
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: alumno.aprueba() ? Colors.green[100] : Colors.red[100],
                        child: Icon(
                          alumno.aprueba() ? Icons.check : Icons.close,
                          color: alumno.aprueba() ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        alumno.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${alumno.matricula} • ${alumno.grupo}'),
                          Text(
                            alumno.nombreMateria,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            calificacion?.toStringAsFixed(2) ?? 'S/C',
                            style: TextStyle(
                              color: alumno.aprueba() ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            alumno.aprueba() ? 'Aprobado' : 'Reprobado',
                            style: TextStyle(
                              fontSize: 10,
                              color: alumno.aprueba() ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        close(context, alumno.nombre);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StudentProfileScreen(
                              matricula: alumno.matricula,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _construirTextoFiltros() {
    List<String> filtros = [];
    if (_filtroEstado != 'todos') {
      filtros.add(_filtroEstado);
    }
    if (_filtroCarrera.isNotEmpty) {
      filtros.add(_filtroCarrera);
    }
    if (_filtroMateria.isNotEmpty) {
      filtros.add(_filtroMateria);
    }
    return filtros.join(', ');
  }
}