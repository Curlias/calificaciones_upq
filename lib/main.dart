import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'providers/config_provider.dart';
import 'providers/data_provider.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar ventana para desktop
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      minimumSize: Size(800, 600),
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Cargar configuración persistida antes de mostrar la app
  final config = ConfigProvider();
  await config.cargar();

  runApp(CalificacionesApp(config: config));
}

class CalificacionesApp extends StatelessWidget {
  final ConfigProvider config;
  const CalificacionesApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: config),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: Consumer<ConfigProvider>(
        builder: (context, configProvider, _) {
          return MaterialApp(
            title: 'Sistema de Calificaciones UPQ',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: configProvider.colorPrimario,
              ),
              fontFamily: configProvider.fuenteSeleccionada,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
