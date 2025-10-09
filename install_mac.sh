#!/bin/bash
# Script para compilar e instalar la aplicación de Calificaciones UPQ en macOS

echo "🔨 Compilando aplicación para macOS..."
echo "⏱️  Este proceso puede tardar 3-5 minutos..."
echo ""

# Obtener el directorio donde está el script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado o no está en el PATH"
    echo "Por favor, instala Flutter desde: https://flutter.dev/docs/get-started/install/macos"
    exit 1
fi

# Compilar en modo release
flutter build macos --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ¡Compilación exitosa!"
    echo ""
    echo "📦 Instalando en /Applications..."
    
    # Copiar la aplicación a Applications
    cp -r build/macos/Build/Products/Release/calificaciones_upq.app /Applications/
    
    # Remover atributos de cuarentena de macOS
    xattr -cr /Applications/calificaciones_upq.app
    
    echo ""
    echo "🎉 ¡Instalación completada!"
    echo ""
    echo "📍 La aplicación está en: /Applications/calificaciones_upq.app"
    echo ""
    echo "🚀 Para ejecutarla:"
    echo "   • Desde Finder: Aplicaciones → calificaciones_upq"
    echo "   • Desde Terminal: open /Applications/calificaciones_upq.app"
    echo ""
    
    # Preguntar si desea abrir la aplicación
    read -p "¿Deseas abrir la aplicación ahora? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        open /Applications/calificaciones_upq.app
    fi
else
    echo ""
    echo "❌ Error en la compilación"
    echo "Revisa los errores arriba para más detalles"
fi
