# 🎓 Sistema de Calificaciones UPQ - Guía de Instalación para macOS

## 📦 Instalación Automática

### Opción 1: Usando el script de instalación (MÁS FÁCIL)

```bash
cd /Users/carlosplata/Documents/GitHub/calificaciones_upq
chmod +x install_mac.sh
./install_mac.sh
```

El script:
- ✅ Compilará la aplicación automáticamente
- ✅ La instalará en `/Applications/`
- ✅ Removerá los atributos de seguridad de macOS
- ✅ Te preguntará si deseas abrirla

---

## 🛠️ Instalación Manual

### Paso 1: Compilar la aplicación

```bash
cd /Users/carlosplata/Documents/GitHub/calificaciones_upq
flutter build macos --release
```

⏱️ **Tiempo estimado**: 3-5 minutos (primera vez)

### Paso 2: Instalar en Applications

```bash
cp -r build/macos/Build/Products/Release/calificaciones_upq.app /Applications/
```

### Paso 3: Remover restricciones de macOS

```bash
xattr -cr /Applications/calificaciones_upq.app
```

### Paso 4: Ejecutar la aplicación

```bash
open /Applications/calificaciones_upq.app
```

O simplemente busca "calificaciones_upq" en Launchpad o Aplicaciones.

---

## 🚀 Primer Uso

### 1. Preparar tu archivo Excel

La aplicación espera un archivo Excel (`.xlsx`) con la siguiente estructura:

**Hoja requerida**: `GruposOfi`

**Columnas necesarias** (37 en total):
- ID
- Matricula
- Alumno
- Genero
- Carrera
- Grupo
- Nombre de la Materia
- Parcial 1, Parcial 2, Parcial 3
- Parcial Final 1, Parcial Final 2, Parcial Final 3
- Faltas P1, Faltas P2, Faltas P3
- Nombre del Profesor
- Nombre del Tutor
- Tipo de Curso (N=Normal, R=Recursamiento)
- ... y más columnas según el formato institucional

### 2. Importar Datos

1. Abre la aplicación
2. Click en el menú lateral (☰)
3. Selecciona "Importar Archivo Excel"
4. Navega hasta tu archivo `.xlsx`
5. Selecciona el archivo
6. ¡Espera a que se procese!

### 3. Explorar el Dashboard

Después de importar verás:
- **Estadísticas generales**: Total de alumnos, grupos, materias, promedios
- **Gráficas interactivas**: Distribución de calificaciones
- **Ranking de grupos**: Los mejores y peores grupos
- **Análisis por carrera**: Estadísticas segmentadas

### 4. Generar Reportes

1. Click en "Reportes" en el menú lateral
2. Selecciona el tipo:
   - **Individual**: Un PDF por alumno
   - **Grupo**: Un PDF por grupo
   - **General**: Reporte institucional completo
3. Aplica filtros si es necesario:
   - Por carrera
   - Por materia
   - Aprobados/Reprobados
   - Recursamiento
4. Click en "Generar Reportes"

Los PDFs se guardarán en tu carpeta de Descargas.

---

## ⚙️ Configuración

### Acceder a Configuración

Click en "Configuración" en el menú lateral.

### Opciones Disponibles

#### 1. Configuración Académica
- **Umbral de Aprobación**: Cambia el mínimo para aprobar (default: 7.0)

#### 2. Información Institucional
- **Nombre de Institución**: Personaliza el nombre
- **Logo**: Sube el logo institucional para los PDFs

#### 3. Personalización Visual
- **Color Primario**: Color principal de la interfaz
- **Color Secundario**: Color de acento
- **Fuente**: Selecciona la tipografía del sistema

#### 4. Opciones de Reportes
- Incluir/excluir firma en PDFs
- Texto de la firma
- Elementos a mostrar en reportes

---

## 📊 Lógica de Calificaciones

El sistema utiliza una lógica específica para calcular calificaciones:

### Cálculo por Parcial

```
SI parcial >= 7.0:
    calificacion_final = (parcial + parcial_final) / 2
SI NO:
    calificacion_final = parcial_final
```

### Calificación Final del Curso

```
calificacion_curso = promedio(parcial1_final, parcial2_final, parcial3_final)
```

### Criterio de Aprobación

```
aprobado = calificacion_curso >= umbral_aprobacion (default 7.0)
```

---

## 🔍 Funcionalidades Avanzadas

### Búsqueda de Alumnos

En cualquier pantalla con listado de alumnos, usa la barra de búsqueda para:
- Buscar por matrícula
- Buscar por nombre
- Filtrar en tiempo real

### Filtros Inteligentes

La aplicación ofrece filtros por:
- **Carrera**: ISC, ITI, IIA, etc.
- **Materia**: Matemáticas, Programación, etc.
- **Estado**: Aprobados, Reprobados, Recursamiento
- **Género**: M/F

### Vista de Detalle de Grupo

Click en cualquier grupo para ver:
- Lista completa de alumnos
- Estadísticas del grupo
- Promedios por parcial
- Distribución de calificaciones
- Identificación de alumnos en riesgo

---

## 🆘 Solución de Problemas

### La aplicación no abre

```bash
xattr -cr /Applications/calificaciones_upq.app
open /Applications/calificaciones_upq.app
```

### Error al importar Excel

Verifica que:
- El archivo tenga extensión `.xlsx`
- Exista la hoja "GruposOfi"
- Las columnas estén en el orden correcto
- No haya celdas con formatos extraños

### La aplicación se cierra inesperadamente

Revisa el log del sistema:
```bash
log show --predicate 'process == "calificaciones_upq"' --last 5m
```

### Reportes no se generan

- Verifica que hayas importado datos
- Confirma que hay alumnos que cumplan los filtros
- Revisa que tengas permisos de escritura en Descargas

---

## 🔄 Actualizar la Aplicación

Para recompilar con cambios:

```bash
cd /Users/carlosplata/Documents/GitHub/upq-app/calificaciones_upq
flutter clean
./install_mac.sh
```

---

## 📝 Notas Importantes

### Datos Privados

- Los datos **NO se envían a ningún servidor**
- Todo se procesa **localmente** en tu Mac
- Los archivos Excel quedan en tu computadora
- Los PDFs se guardan solo en tu carpeta de Descargas

### Rendimiento

- **Alumnos recomendados**: Hasta 10,000 registros
- **Tiempo de importación**: ~10-30 segundos para 1,000 registros
- **Generación de PDFs**: ~1-2 segundos por documento

### Compatibilidad

- **macOS**: 10.15 (Catalina) o superior
- **Arquitectura**: Intel x86_64 y Apple Silicon (M1/M2/M3)
- **Excel**: Compatible con archivos `.xlsx` de Excel 2007+

---

## 📞 Soporte

Para problemas técnicos o preguntas:

1. Revisa esta guía completa
2. Verifica los logs de errores
3. Consulta el código fuente en el repositorio
4. Contacta al equipo de desarrollo

---

## 📄 Licencia

Esta aplicación fue desarrollada específicamente para la **Universidad Politécnica de Querétaro**.

---

**Desarrollado con ❤️ para la comunidad académica de la UPQ**

Versión: 1.0.0  
Fecha: Octubre 2025
