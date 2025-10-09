#!/bin/bash
# Script para compilar la aplicación de macOS evitando problemas de firma

set -e

echo "🧹 Limpiando proyecto..."
flutter clean
rm -rf build macos/Pods macos/Podfile.lock

echo "📦 Obteniendo dependencias..."
flutter pub get

echo "🔧 Limpiando atributos extendidos..."
xattr -cr .

echo "🎯 Compilando en segundo plano (para poder limpiar durante el build)..."

# Crear un script temporal que limpia atributos durante el build
cat > /tmp/clean_attrs.sh << 'EOF'
#!/bin/bash
while true; do
    find /Users/carlosplata/Documents/GitHub/calificaciones_upq/build -name "*.app" -exec xattr -cr {} \; 2>/dev/null || true
    sleep 0.5
done
EOF

chmod +x /tmp/clean_attrs.sh

# Iniciar el limpiador en segundo plano
/tmp/clean_attrs.sh &
CLEANER_PID=$!

# Intentar compilar
flutter build macos --release

# Detener el limpiador
kill $CLEANER_PID 2>/dev/null || true

# Limpieza final
if [ -d "build/macos/Build/Products/Release/calificaciones_upq.app" ]; then
    echo "✅ ¡Compilación exitosa!"
    echo "📦 Instalando..."
    
    xattr -cr build/macos/Build/Products/Release/calificaciones_upq.app
    cp -r build/macos/Build/Products/Release/calificaciones_upq.app /Applications/
    xattr -cr /Applications/calificaciones_upq.app
    
    echo "🎉 ¡Instalación completada!"
    echo ""
    read -p "¿Deseas abrir la aplicación ahora? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        open /Applications/calificaciones_upq.app
    fi
else
    echo "❌ Error: No se encontró la aplicación compilada"
    exit 1
fi
