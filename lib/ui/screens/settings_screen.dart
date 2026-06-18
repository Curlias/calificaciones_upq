import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/config_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreInstitucionController;
  late TextEditingController _textoFirmaController;

  @override
  void initState() {
    super.initState();
    final config = Provider.of<ConfigProvider>(context, listen: false);
    _nombreInstitucionController = TextEditingController(text: config.nombreInstitucion);
    _textoFirmaController = TextEditingController(text: config.textoFirma);
  }

  @override
  void dispose() {
    _nombreInstitucionController.dispose();
    _textoFirmaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, configProvider, child) {
        return Theme(
          data: configProvider.tema,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Configuración'),
              elevation: 2,
              actions: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: _mostrarDialogoReset,
                  tooltip: 'Restablecer configuración',
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _guardarConfiguracion,
                  tooltip: 'Guardar configuración',
                ),
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Configuración Académica
                  _buildSeccionTarjeta(
                    'Configuración Académica',
                    Icons.school,
                    [
                      _buildUmbralAprobacion(configProvider),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Configuración Institucional
                  _buildSeccionTarjeta(
                    'Información Institucional',
                    Icons.business,
                    [
                      _buildNombreInstitucion(configProvider),
                      const SizedBox(height: 16),
                      _buildSelectorLogo(configProvider),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Configuración Visual
                  _buildSeccionTarjeta(
                    'Configuración Visual',
                    Icons.palette,
                    [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Modo oscuro',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        subtitle: const Text('Cambia la apariencia de la aplicación'),
                        secondary: Icon(
                          configProvider.modoOscuro ? Icons.dark_mode : Icons.light_mode,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        value: configProvider.modoOscuro,
                        onChanged: (value) => configProvider.modoOscuro = value,
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildSelectorColor(
                        'Color Primario',
                        configProvider.colorPrimario,
                        (color) => configProvider.colorPrimario = color,
                      ),
                      const SizedBox(height: 16),
                      _buildSelectorColor(
                        'Color Secundario',
                        configProvider.colorSecundario,
                        (color) => configProvider.colorSecundario = color,
                      ),
                      const SizedBox(height: 16),
                      _buildSelectorFuente(configProvider),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Configuración de Reportes
                  _buildSeccionTarjeta(
                    'Configuración de Reportes',
                    Icons.picture_as_pdf,
                    [
                      _buildOpcionesReportes(configProvider),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Información del sistema
                  _buildInformacionSistema(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeccionTarjeta(String titulo, IconData icono, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUmbralAprobacion(ConfigProvider configProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Umbral de Aprobación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                configProvider.umbralAprobacion.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: configProvider.umbralAprobacion,
          min: 5.0,
          max: 10.0,
          divisions: 50,
          label: configProvider.umbralAprobacion.toStringAsFixed(1),
          onChanged: (value) {
            configProvider.umbralAprobacion = value;
          },
        ),
        Text(
          'Los alumnos necesitan una calificación de ${configProvider.umbralAprobacion.toStringAsFixed(1)} o superior para aprobar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNombreInstitucion(ConfigProvider configProvider) {
    return TextFormField(
      controller: _nombreInstitucionController,
      decoration: const InputDecoration(
        labelText: 'Nombre de la Institución',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El nombre de la institución es requerido';
        }
        return null;
      },
      onChanged: (value) {
        configProvider.nombreInstitucion = value;
      },
    );
  }

  Widget _buildSelectorLogo(ConfigProvider configProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo Institucional',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        configProvider.logoPath ?? 'No se ha seleccionado logo',
                        style: TextStyle(
                          color: configProvider.logoPath != null 
                              ? Colors.black87 
                              : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _seleccionarLogo,
              child: const Text('Seleccionar'),
            ),
            if (configProvider.logoPath != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => configProvider.logoPath = null,
                icon: const Icon(Icons.clear),
                tooltip: 'Quitar logo',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSelectorColor(String titulo, Color colorActual, Function(Color) onChanged) {
    final colores = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colores.map((color) {
            final isSelected = color.value == colorActual.value;
            return GestureDetector(
              onTap: () => onChanged(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected 
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectorFuente(ConfigProvider configProvider) {
    final fuentes = ['Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Source Sans Pro'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fuente del Sistema',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: configProvider.fuenteSeleccionada,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.text_fields),
          ),
          items: fuentes.map((fuente) {
            return DropdownMenuItem(
              value: fuente,
              child: Text(fuente, style: TextStyle(fontFamily: fuente)),
            );
          }).toList(),
          onChanged: (fuente) {
            if (fuente != null) {
              configProvider.fuenteSeleccionada = fuente;
            }
          },
        ),
      ],
    );
  }

  Widget _buildOpcionesReportes(ConfigProvider configProvider) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Incluir logos en reportes'),
          subtitle: const Text('Mostrar el logo institucional en los PDFs generados'),
          value: configProvider.incluirLogosEnReportes,
          onChanged: (value) {
            configProvider.incluirLogosEnReportes = value;
          },
        ),
        SwitchListTile(
          title: const Text('Incluir firma en reportes'),
          subtitle: const Text('Agregar texto de firma al pie de los reportes'),
          value: configProvider.incluirFirmaEnReportes,
          onChanged: (value) {
            configProvider.incluirFirmaEnReportes = value;
          },
        ),
        if (configProvider.incluirFirmaEnReportes) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _textoFirmaController,
            decoration: const InputDecoration(
              labelText: 'Texto de la firma',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
              hintText: 'Ej: Director Académico, Coordinador, etc.',
            ),
            onChanged: (value) {
              configProvider.textoFirma = value;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInformacionSistema() {
    return Card(
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
                  'Información del Sistema',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Sistema de Calificaciones UPQ'),
            const Text('Versión 1.0.0'),
            const Text('Desarrollado para la Universidad Politécnica de Querétaro'),
          ],
        ),
      ),
    );
  }

  void _seleccionarLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final configProvider = Provider.of<ConfigProvider>(context, listen: false);
      configProvider.logoPath = result.files.first.path;
    }
  }

  void _guardarConfiguracion() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _mostrarDialogoReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restablecer Configuración'),
          content: const Text(
            '¿Está seguro de que desea restablecer toda la configuración a los valores predeterminados?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final configProvider = Provider.of<ConfigProvider>(context, listen: false);
                configProvider.resetearConfiguracion();
                _nombreInstitucionController.text = configProvider.nombreInstitucion;
                _textoFirmaController.text = configProvider.textoFirma;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración restablecida'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Restablecer'),
            ),
          ],
        );
      },
    );
  }
}