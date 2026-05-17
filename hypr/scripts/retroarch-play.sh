#!/bin/bash

# Script que detecta juegos y genera scripts individuales para ejecutarlos

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directorios
GAMES_DIR="$HOME/Documentos/Juegos"
CORES_DIR="$HOME/.var/app/org.libretro.RetroArch/config/retroarch/cores"
SCRIPTS_DIR="$HOME/Documentos/Juegos/Scripts"

# Crear directorio para scripts si no existe
mkdir -p "$SCRIPTS_DIR"

# Asociaciones de extensiones a cores
declare -A CORE_MAP
CORE_MAP["nes"]="nestopia_libretro.so"
CORE_MAP["sfc"]="snes9x_libretro.so"
CORE_MAP["smc"]="snes9x_libretro.so"
CORE_MAP["md"]="genesis_plus_gx_libretro.so"
CORE_MAP["gen"]="genesis_plus_gx_libretro.so"
CORE_MAP["gba"]="mgba_libretro.so"
CORE_MAP["gb"]="gambatte_libretro.so"
CORE_MAP["gbc"]="gambatte_libretro.so"
CORE_MAP["n64"]="mupen64plus_next_libretro.so"
CORE_MAP["z64"]="mupen64plus_next_libretro.so"
CORE_MAP["v64"]="mupen64plus_next_libretro.so"
CORE_MAP["psx"]="pcsx_rearmed_libretro.so"
CORE_MAP["cue"]="pcsx_rearmed_libretro.so"
CORE_MAP["bin"]="pcsx_rearmed_libretro.so"
CORE_MAP["nds"]="desmume_libretro.so"

echo -e "${BLUE}=== Generador de Scripts para RetroArch ===${NC}\n"

# Verificar que existe el directorio de juegos
if [ ! -d "$GAMES_DIR" ]; then
    echo -e "${RED}Error: No existe el directorio $GAMES_DIR${NC}"
    exit 1
fi

# Verificar que existe RetroArch Flatpak
if ! flatpak list | grep -q "org.libretro.RetroArch"; then
    echo -e "${RED}Error: RetroArch no está instalado con Flatpak${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Directorio de juegos encontrado: $GAMES_DIR${NC}"
echo -e "${GREEN}✓ RetroArch Flatpak detectado${NC}\n"

# Contador de scripts generados
COUNT=0

# Buscar juegos recursivamente
echo -e "${YELLOW}Buscando juegos...${NC}\n"

for ext in "${!CORE_MAP[@]}"; do
    while IFS= read -r -d '' game; do
        GAME_NAME=$(basename "$game")
        GAME_BASE="${GAME_NAME%.*}"
        EXTENSION="${GAME_NAME##*.}"
        CORE_FILE="${CORE_MAP[$EXTENSION]}"
        CORE_PATH="$CORES_DIR/$CORE_FILE"
        
        # Nombre del script (sanitizado)
        SCRIPT_NAME=$(echo "$GAME_BASE" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        SCRIPT_PATH="$SCRIPTS_DIR/play_$SCRIPT_NAME.sh"
        
        # Verificar si el core existe
        if [ ! -f "$CORE_PATH" ]; then
            echo -e "${YELLOW}⚠ Juego encontrado pero core no disponible: $GAME_NAME (necesita $CORE_FILE)${NC}"
            continue
        fi
        
        # Generar el script
        cat > "$SCRIPT_PATH" << EOF
#!/bin/bash

# Script auto-generado para ejecutar: $GAME_NAME
# Core: ${CORE_FILE%.so}
# Generado: $(date)

flatpak run org.libretro.RetroArch -L "$CORE_PATH" "$game"
EOF
        
        # Dar permisos de ejecución
        chmod +x "$SCRIPT_PATH"
        
        echo -e "${GREEN}✓ Script creado: play_$SCRIPT_NAME.sh${NC}"
        echo -e "  Juego: $GAME_NAME"
        echo -e "  Core: ${CORE_FILE%.so}\n"
        
        ((COUNT++))
    done < <(find "$GAMES_DIR" -type f -iname "*.$ext" -print0)
done

echo -e "${BLUE}===========================================${NC}"
if [ $COUNT -eq 0 ]; then
    echo -e "${YELLOW}No se encontraron juegos compatibles en $GAMES_DIR${NC}"
    echo -e "\n${YELLOW}Extensiones soportadas:${NC}"
    for ext in "${!CORE_MAP[@]}"; do
        echo "  - .$ext (${CORE_MAP[$ext]%.so})"
    done
else
    echo -e "${GREEN}✓ Se generaron $COUNT scripts en: $SCRIPTS_DIR${NC}"
    echo -e "\n${YELLOW}Para ejecutar un juego:${NC}"
    echo -e "  cd $SCRIPTS_DIR"
    echo -e "  ./play_nombre_del_juego.sh"
fi
echo -e "${BLUE}===========================================${NC}"