# 🚀 INICIO RÁPIDO - Sistema de Calificaciones UPQ

## ⚡ Instalación en 3 Pasos

### 1️⃣ Compilar e Instalar
```bash
cd /Users/carlosplata/Documents/GitHub/upq-app/calificaciones_upq
./install_mac.sh
```

### 2️⃣ Abrir la Aplicación
```bash
open /Applications/calificaciones_upq.app
```

### 3️⃣ Importar tus Datos
- Click en el menú (☰)
- Selecciona "Importar Archivo Excel"
- Busca tu archivo `.xlsx` con la hoja "GruposOfi"
- ¡Listo!

---

## 📂 Formato del Archivo Excel Requerido

- **Nombre de Hoja**: `GruposOfi`
- **Formato**: `.xlsx` (Excel 2007+)
- **Columnas**: 37 columnas incluyendo:
  - ID, Matrícula, Alumno, Género, Carrera, Grupo
  - Nombre de la Materia
  - Parcial 1, 2, 3
  - Parcial Final 1, 2, 3
  - Faltas P1, P2, P3
  - Nombre del Profesor, Nombre del Tutor
  - Tipo de Curso (N/R)
  - ...y más

---

## 🎯 Funciones Principales

### Dashboard
- Ver estadísticas generales
- Gráficas de distribución
- Ranking de grupos

### Reportes
- PDFs individuales por alumno
- Reportes de grupo
- Reporte institucional completo

### Configuración
- Ajustar umbral de aprobación
- Personalizar colores
- Subir logo institucional

---

## 🆘 ¿Problemas?

### La app no abre
```bash
xattr -cr /Applications/calificaciones_upq.app
open /Applications/calificaciones_upq.app
```

### Error al importar Excel
- Verifica que la hoja se llame "GruposOfi"
- Confirma que el archivo sea `.xlsx`
- Revisa que tenga las 37 columnas

### Recompilar desde cero
```bash
cd /Users/carlosplata/Documents/GitHub/upq-app/calificaciones_upq
flutter clean
flutter pub get
flutter build macos --release
cp -r build/macos/Build/Products/Release/calificaciones_upq.app /Applications/
```

---

## 📞 Más Información

- **README completo**: `README.md`
- **Guía de instalación**: `INSTALACION_MAC.md`
- **Resumen técnico**: `RESUMEN_INSTALACION.md`

---

**¡Listo para usar! 🎉**
