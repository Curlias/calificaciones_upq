# Sistema de Calificaciones UPQ

Una aplicación Flutter Desktop para la gestión y análisis de calificaciones estudiantiles desarrollada para la Universidad Politécnica de Querétaro.

## 🚀 Características Principales

### 📊 Importación y Procesamiento de Datos
- **Importación de Excel**: Lee archivos `.xlsx` con datos de calificaciones desde la hoja "GruposOfi"
- **Validación automática**: Verifica la estructura del archivo antes de la importación
- **Procesamiento inteligente**: Convierte automáticamente los datos en modelos estructurados

### 🧮 Sistema de Calificaciones Inteligente
- **Lógica de cálculo personalizada**:
  - Si parcial ≥ 7: promedio (parcial + final) / 2
  - Si parcial < 7: usar solo parcial final
  - Calificación final: promedio de los 3 parciales calculados
- **Umbral configurable**: Ajuste del umbral de aprobación (por defecto 7.0)
- **Manejo de datos faltantes**: Identificación de registros "Sin calificar"

### 📈 Dashboard Completo
- **Estadísticas generales**: Total de alumnos, grupos, materias y promedios
- **Gráficas interactivas**: Distribución de calificaciones con Syncfusion Charts
- **Análisis por carrera**: Estadísticas segmentadas por programa académico
- **Tabla de grupos**: Ranking de grupos por rendimiento

### 👥 Gestión de Grupos
- **Vista detallada**: Información completa de cada grupo
- **Análisis por parciales**: Estadísticas de rendimiento por período
- **Gestión de faltas**: Seguimiento de asistencia
- **Identificación de recursamiento**: Alumnos en segunda oportunidad

### 📋 Sistema de Reportes
- **Reportes individuales**: PDF personalizado por alumno
- **Reportes de grupo**: Resumen completo del grupo con estadísticas
- **Reporte general**: Vista institucional completa
- **Personalización**: Logo institucional y firma en PDFs

### ⚙️ Configuración Avanzada
- **Personalización visual**: Colores institucionales y fuentes
- **Configuración académica**: Umbral de aprobación ajustable
- **Opciones de reporte**: Control de elementos incluidos en PDFs
- **Filtros avanzados**: Por carrera, materia, estado académico

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Flutter SDK (3.0 o superior)
- Dart SDK
- Plataforma de destino (Windows, macOS, o Linux)

### Dependencias Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2                    # Gestión de estado
  syncfusion_flutter_xlsio: ^26.2.14  # Procesamiento Excel
  syncfusion_flutter_charts: ^26.2.14 # Gráficas
  pdf: ^3.11.1                        # Generación PDF
  printing: ^5.13.2                   # Impresión PDF
  file_picker: ^8.1.2                 # Selector de archivos
  path_provider: ^2.1.4               # Gestión de rutas
  window_manager: ^0.4.2              # Control de ventana desktop
```

### Instalación
1. **Clonar el repositorio**:
   ```bash
   git clone [repository-url]
   cd calificaciones_upq
   ```

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**:
   ```bash
   # Para macOS
   flutter run -d macos
   
   # Para Windows
   flutter run -d windows
   
   # Para Linux
   flutter run -d linux
   ```

## 📁 Estructura del Proyecto

```
lib/
├── models/                 # Modelos de datos
│   ├── alumno.dart        # Modelo de alumno con lógica de calificaciones
│   ├── grupo.dart         # Modelo de grupo con estadísticas
│   └── reporte.dart       # Modelos para reportes
├── services/              # Servicios
│   ├── excel_service.dart # Procesamiento de archivos Excel
│   └── pdf_service.dart   # Generación de PDFs
├── providers/             # Gestión de estado
│   ├── config_provider.dart # Configuración global
│   └── data_provider.dart   # Datos de la aplicación
├── ui/
│   ├── screens/           # Pantallas principales
│   │   ├── home_screen.dart
│   │   ├── import_screen.dart
│   │   ├── report_screen.dart
│   │   ├── settings_screen.dart
│   │   └── group_detail_screen.dart
│   └── widgets/           # Widgets reutilizables
│       ├── estadisticas_card.dart
│       ├── grafica_distribucion.dart
│       └── tabla_grupos.dart
└── main.dart              # Punto de entrada
```

## 📊 Formato de Archivo Excel

### Estructura Requerida (Hoja "GruposOfi")
El archivo Excel debe contener las siguientes columnas:

| Columna | Descripción | Tipo |
|---------|-------------|------|
| ID | Identificador único | String |
| Matricula | Matrícula del alumno | String |
| Alumno | Nombre completo | String |
| Genero | M/F | String |
| Carrera | Programa académico | String |
| Grupo | Grupo del alumno | String |
| Nombre de la Materia | Materia cursada | String |
| Parcial 1, 2, 3 | Calificaciones parciales | Double (0-10) |
| Parcial Final 1, 2, 3 | Exámenes finales | Double (0-10) |
| Faltas P1, P2, P3 | Faltas por parcial | Integer |
| Nombre del Profesor | Docente | String |
| Nombre del Tutor | Tutor (opcional) | String |
| Tipo de Curso | N=Normal, R=Recursamiento | String |

### Ejemplo de Datos
```
ID    | Matricula | Alumno        | Genero | Carrera | Grupo  | Parcial 1 | Parcial Final 1
------|-----------|---------------|--------|---------|--------|-----------|----------------
12345 | 2021001   | Juan Pérez    | M      | ISC     | IRT201 | 8.5       | 9.0
12346 | 2021002   | María García  | F      | ISC     | IRT201 | 6.0       | 7.5
```

## 🎯 Casos de Uso

### 1. Coordinador Académico
- Importar calificaciones del período
- Generar reportes institucionales
- Analizar rendimiento por carrera
- Identificar grupos con bajo rendimiento

### 2. Profesor
- Consultar estadísticas de sus grupos
- Generar reportes de grupo
- Analizar rendimiento por parcial
- Identificar alumnos en riesgo

### 3. Servicios Escolares
- Generar reportes individuales masivos
- Configurar parámetros institucionales
- Exportar datos para procesos administrativos
- Mantener configuración del sistema

## 🔧 Configuración Avanzada

### Umbral de Aprobación
```dart
// Configuración por defecto: 7.0
// Modificable desde Settings > Configuración Académica
configProvider.umbralAprobacion = 7.5;
```

### Personalización Visual
```dart
// Colores institucionales
configProvider.colorPrimario = Colors.blue;
configProvider.colorSecundario = Colors.indigo;

// Fuente del sistema
configProvider.fuenteSeleccionada = 'Roboto';
```

### Configuración de Reportes
```dart
// Logo institucional
configProvider.logoPath = '/path/to/logo.png';

// Firma en reportes
configProvider.incluirFirmaEnReportes = true;
configProvider.textoFirma = 'Director Académico';
```

## 📱 Funcionalidades por Pantalla

### Dashboard (Pantalla Principal)
- **Navegación lateral**: Drawer con acceso a todas las funciones
- **Estadísticas generales**: Cards con métricas principales
- **Gráficas interactivas**: Distribución de calificaciones
- **Ranking de grupos**: Tabla con mejores grupos

### Importación
- **Validación de archivo**: Verificación automática de estructura
- **Progreso visual**: Indicadores de carga y estado
- **Manejo de errores**: Mensajes descriptivos de problemas

### Reportes
- **Filtros avanzados**: Por tipo, carrera, materia, estado
- **Vista previa**: Información de lo que se incluirá
- **Generación masiva**: Múltiples reportes en una operación

### Configuración
- **Configuración académica**: Umbral de aprobación
- **Información institucional**: Nombre y logo
- **Personalización visual**: Colores y fuentes
- **Opciones de reportes**: Elementos a incluir en PDFs

## 🚨 Manejo de Errores

### Validación de Archivos Excel
- Verificación de existencia de hoja "GruposOfi"
- Validación de columnas requeridas
- Detección de formatos incorrectos
- Mensajes específicos por tipo de error

### Validación de Datos
- Calificaciones fuera de rango (0-10)
- Campos requeridos faltantes
- Inconsistencias en tipos de datos
- Registros duplicados

## 🔄 Flujo de Trabajo Recomendado

1. **Configuración inicial**: Establecer parámetros institucionales
2. **Importación de datos**: Cargar archivo Excel del período
3. **Validación**: Revisar estadísticas generales en dashboard
4. **Análisis**: Explorar grupos y materias con bajo rendimiento
5. **Reportes**: Generar documentos según necesidades
6. **Seguimiento**: Uso de filtros para casos específicos

## 📞 Soporte y Contribución

### Reportar Problemas
Al reportar un problema, incluya:
- Versión de Flutter utilizada
- Plataforma (Windows/macOS/Linux)
- Descripción detallada del error
- Archivo Excel de ejemplo (si aplica)

### Contribuir al Proyecto
1. Fork del repositorio
2. Crear rama para nueva funcionalidad
3. Implementar cambios con tests
4. Documentar nuevas características
5. Crear Pull Request

## 📄 Licencia

Este proyecto está desarrollado para la Universidad Politécnica de Querétaro.

---

**Desarrollado con ❤️ para la comunidad académica de la UPQ**
