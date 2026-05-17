#!/bin/bash
# Theme Switcher para Hyprland en CachyOS
# Incluye: GTK3/4, Kitty, Rofi, Waybar, AWWW, SwayNC, VSCodium, Spicetify, Hyprlock, Cursor, Iconos, Música

# ========== CONFIGURACIÓN ==========
CONFIG_DIR="$HOME/.config"
HYPR_DIR="$CONFIG_DIR/hypr"
THEMES_DIR="$HYPR_DIR/themes"
KITTY_DIR="$CONFIG_DIR/kitty"
ROFI_DIR="$CONFIG_DIR/rofi"
WAYBAR_DIR="$CONFIG_DIR/waybar"
SWAYNC_DIR="$CONFIG_DIR/swaync"
WALLPAPERS_DIR="$HOME/Imágenes/Wallpapers"
VSCODIUM_DIR="$CONFIG_DIR/VSCodium/User"
SPICETIFY_DIR="$CONFIG_DIR/spicetify"
HYPRLOCK_DIR="$HYPR_DIR/hyprlock"
MUSIC_DIR="$HOME/Música/themes"
SWAYOSD_DIR="$CONFIG_DIR/swayosd"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variable global para el PID del reproductor de música
THEME_MUSIC_PID=""

# ========== FUNCIONES DE UTILIDAD ==========

notify() {
    echo -e "${GREEN}[✓]${NC} $1"
    notify-send "Theme Switcher" "$1" -i preferences-desktop-theme
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    notify-send "Theme Switcher Error" "$1" -u critical -i dialog-error
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# ========== FUNCIONES DE TEMA ==========

# Listar temas disponibles
list_themes() {
    if [[ -d "$THEMES_DIR" ]]; then
        themes=($(ls -d "$THEMES_DIR"/*/ 2>/dev/null | xargs -n 1 basename))
        if [[ ${#themes[@]} -eq 0 ]]; then
            error "No hay temas disponibles en $THEMES_DIR"
            return 1
        fi
        echo "${themes[@]}"
    else
        error "Directorio de temas no encontrado: $THEMES_DIR"
        return 1
    fi
}

# Aplicar tema GTK (GTK3 y GTK4)
apply_gtk_theme() {
    local theme_name="$1"
    local icon_theme="$2"
    local cursor_theme="$3"
    
    # Usar la variable del theme.conf o por defecto "prefer-dark"
    local color_scheme="${GTK_COLOR_SCHEME:-prefer-dark}"
    
    info "Aplicando tema GTK y esquema de color ($color_scheme)..."
    
    # 1. Ajustar el esquema de color (Dark/Light mode)
    gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
    
    # 2. Aplicar el nombre del tema GTK
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
    
    # 3. Forzar el modo oscuro en aplicaciones GTK4 antiguas/Legacy
    if [[ "$color_scheme" == "prefer-dark" ]]; then
        gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme true
    else
        gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme false
    fi
    
    # 4. Iconos y Cursor
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
    if [[ -n "$cursor_theme" ]]; then
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"
        hyprctl setcursor "$cursor_theme" 24 2>/dev/null
    fi
    
}

# Aplicar tema Kitty
apply_kitty_theme() {
    local theme_name="$1"
    
    info "Aplicando tema Kitty..."
    
    local theme_file=""
    
    if [[ -f "$KITTY_DIR/themes/${theme_name}.conf" ]]; then
        theme_file="$KITTY_DIR/themes/${theme_name}.conf"
    elif [[ -f "$THEMES_DIR/$theme_name/kitty.conf" ]]; then
        theme_file="$THEMES_DIR/$theme_name/kitty.conf"
    else
        error "Tema Kitty no encontrado: $theme_name"
        return 1
    fi
    
    ln -sf "$theme_file" "$KITTY_DIR/current-theme.conf"
    kitty @ set-colors --all --configured "$theme_file" 2>/dev/null || \
        info "No hay instancias de Kitty en ejecución"
    
}

# Aplicar tema Rofi
apply_rofi_theme() {
    local theme_name="$1"
    
    info "Aplicando tema Rofi..."
    
    local theme_file=""
    
    # Buscar tema en orden de prioridad
    if [[ -f "$ROFI_DIR/themes/${theme_name}.rasi" ]]; then
        theme_file="$ROFI_DIR/themes/${theme_name}.rasi"
    elif [[ -f "$THEMES_DIR/$theme_name/rofi.rasi" ]]; then
        theme_file="$THEMES_DIR/$theme_name/rofi.rasi"
    elif [[ -f "$THEMES_DIR/$theme_name/rofi/config.rasi" ]]; then
        theme_file="$THEMES_DIR/$theme_name/rofi/config.rasi"
    else
        info "Tema Rofi no encontrado para: $theme_name (usando tema por defecto)"
        return 0
    fi
    
    # Crear o actualizar archivo de configuración principal de Rofi
    mkdir -p "$ROFI_DIR"
    
    if [[ ! -f "$ROFI_DIR/config.rasi" ]]; then
        cat > "$ROFI_DIR/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,window,ssh,filebrowser";
    show-icons: true;
    icon-theme: "Papirus";
    display-drun: "  Apps";
    display-run: "  Run";
    display-window: "  Windows";
    display-ssh: "  SSH";
    display-filebrowser: "  Files";
    drun-display-format: "{name}";
    window-format: "{w} · {c} · {t}";
    font: "JetBrainsMono Nerd Font 10";
    terminal: "kitty";
}

@theme "current-theme.rasi"
EOF
    fi
    
    # Crear symlink al tema actual
    ln -sf "$theme_file" "$ROFI_DIR/current-theme.rasi"
    
    # Si hay archivos de colores/configuración adicionales
    if [[ -d "$THEMES_DIR/$theme_name/rofi" ]]; then
        # Copiar archivos de colores y fuentes si existen
        if [[ -f "$THEMES_DIR/$theme_name/rofi/colors.rasi" ]]; then
            cp "$THEMES_DIR/$theme_name/rofi/colors.rasi" "$ROFI_DIR/colors.rasi"
        fi
        if [[ -f "$THEMES_DIR/$theme_name/rofi/fonts.rasi" ]]; then
            cp "$THEMES_DIR/$theme_name/rofi/fonts.rasi" "$ROFI_DIR/fonts.rasi"
        fi
    fi
    
}

# Aplicar tema Waybar
apply_waybar_theme() {
    local theme_name="$1"
    
    info "Aplicando tema Waybar..."
    
    local style_file="$WAYBAR_DIR/styles/${theme_name}.css"
    
    if [[ ! -f "$style_file" ]]; then
        style_file="$THEMES_DIR/$theme_name/waybar.css"
    fi
    
    if [[ -f "$style_file" ]]; then
        ln -sf "$style_file" "$WAYBAR_DIR/style.css"
        killall waybar
        waybar &>/dev/null &
    else
        error "Estilo Waybar no encontrado para: $theme_name"
    fi
}


# Aplicar tema SwayNC
apply_swaync_theme() {
    local theme_name="$1"
    
    info "Aplicando tema SwayNC..."
    
    local style_file="$SWAYNC_DIR/styles/${theme_name}.css"
    
    if [[ ! -f "$style_file" ]]; then
        style_file="$THEMES_DIR/$theme_name/swaync.css"
    fi
    
    if [[ -f "$style_file" ]]; then
        ln -sf "$style_file" "$SWAYNC_DIR/style.css"
        swaync-client --reload-css 2>/dev/null || \
            info "SwayNC no está en ejecución"
    else
        info "Tema SwayNC no encontrado (opcional)"
    fi
}

# Aplicar tema VSCodium
apply_vscodium_theme() {
    local theme_name="$1"
    local vscodium_theme="${VSCODIUM_THEME:-}"
    
    info "Aplicando tema VSCodium..."
    
    if [[ -z "$vscodium_theme" ]]; then
        info "VSCodium tema no especificado en theme.conf"
        return 0
    fi
    
    local settings_file="$VSCODIUM_DIR/settings.json"
    
    if [[ ! -f "$settings_file" ]]; then
        mkdir -p "$VSCODIUM_DIR"
        echo '{}' > "$settings_file"
    fi
    
    if command -v jq &> /dev/null; then
        local temp_file=$(mktemp)
        jq --arg theme "$vscodium_theme" '.["workbench.colorTheme"] = $theme' "$settings_file" > "$temp_file"
        mv "$temp_file" "$settings_file"
    else
        if grep -q "workbench.colorTheme" "$settings_file"; then
            sed -i "s/\"workbench.colorTheme\":.*/\"workbench.colorTheme\": \"$vscodium_theme\",/" "$settings_file"
        else
            sed -i "s/^{/{\n  \"workbench.colorTheme\": \"$vscodium_theme\",/" "$settings_file"
        fi
    fi
}

# Aplicar tema Spicetify
apply_spicetify_theme() {
    local theme_name="$1"
    local spicetify_theme="${SPICETIFY_THEME:-}"
    local spicetify_scheme="${SPICETIFY_SCHEME:-}"
    
    info "Aplicando tema Spicetify..."
    
    if ! command -v spicetify &> /dev/null; then
        info "Spicetify no está instalado"
        return 0
    fi
    
    if [[ -z "$spicetify_theme" ]]; then
        info "Spicetify tema no especificado en theme.conf"
        return 0
    fi
    
    spicetify config current_theme "$spicetify_theme" 2>/dev/null
    
    if [[ -n "$spicetify_scheme" ]]; then
        spicetify config color_scheme "$spicetify_scheme" 2>/dev/null
    fi
    
    # Aplicar cambios
    spicetify apply 2>/dev/null

    # --- NUEVA SECCIÓN PARA FLATPAK ---
    info "Reiniciando Spotify (Flatpak)..."
    kill spotify 2>/dev/null
    # Abrir en segundo plano sin bloquear el script
    spotify &>/dev/null & 
}

# Aplicar pywal y pywalfox
apply_pywal() {
    local wallpaper_path="$1"
    
    if ! command -v wal &> /dev/null; then
        info "pywal no está instalado (opcional)"
        return 0
    fi
    
    info "Generando esquema de colores con pywal..."
    
    wal -i "$wallpaper_path" -q
    
    if command -v pywalfox &> /dev/null; then
        info "Actualizando Firefox con pywalfox..."
        pywalfox update 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            notify "Firefox actualizado con pywalfox"
        else
            info "pywalfox: Firefox no está en ejecución o extensión no instalada"
        fi
    fi
}

# Aplicar tema Hyprlock
apply_hyprlock_theme() {
    local theme_name="$1"
    
    info "Aplicando tema Hyprlock..."
    
    local hyprlock_file="$THEMES_DIR/$theme_name/hyprlock.conf"
    
    if [[ -f "$hyprlock_file" ]]; then
        mkdir -p "$HYPRLOCK_DIR"
        ln -sf "$hyprlock_file" "$CONFIG_DIR/hypr/hyprlock.conf"
    else
        info "Configuración Hyprlock no encontrada (opcional)"
    fi
}

# Aplicar wallpaper con AWWW
apply_wallpaper() {
    local theme_name="$1"
    local wallpaper_path=""
    local transition_type="${AWWW_TRANSITION:-fade}"
    local transition_duration="${AWWW_DURATION:-2}"
    local transition_fps="${AWWW_FPS:-60}"
    local transition_bezier="${AWWW_BEZIER:-.43,1.19,1,.4}"
    local use_pywal="${USE_PYWAL:-true}"
    
    info "Aplicando wallpaper..."
    
    if ! pgrep -x awww-daemon > /dev/null; then
        info "Iniciando awww daemon..."
        awww init &
        sleep 1
    fi
    
    if [[ -f "$THEMES_DIR/$theme_name/wallpaper.jpg" ]]; then
        wallpaper_path="$THEMES_DIR/$theme_name/wallpaper.jpg"
    elif [[ -f "$THEMES_DIR/$theme_name/wallpaper.png" ]]; then
        wallpaper_path="$THEMES_DIR/$theme_name/wallpaper.png"
    elif [[ -f "$THEMES_DIR/$theme_name/wallpaper.gif" ]]; then
        wallpaper_path="$THEMES_DIR/$theme_name/wallpaper.gif"    
    elif [[ -f "$WALLPAPERS_DIR/$theme_name.jpg" ]]; then
        wallpaper_path="$WALLPAPERS_DIR/$theme_name.jpg"
    elif [[ -f "$WALLPAPERS_DIR/$theme_name.png" ]]; then
        wallpaper_path="$WALLPAPERS_DIR/$theme_name.png"
    else
        info "Wallpaper no encontrado para tema: $theme_name"
        return 0
    fi
    
    local cursor_pos=""
    if command -v hyprctl &> /dev/null; then
        cursor_pos=$(hyprctl cursorpos 2>/dev/null)
    fi
    
    if [[ -n "$cursor_pos" ]]; then
        awww img "$wallpaper_path" \
            --transition-type "$transition_type" \
            --transition-duration "$transition_duration" \
            --transition-fps "$transition_fps" \
            --transition-bezier "$transition_bezier" \
            --transition-pos "$cursor_pos" 2>/dev/null
    else
        awww img "$wallpaper_path" \
            --transition-type "$transition_type" \
            --transition-duration "$transition_duration" \
            --transition-fps "$transition_fps" \
            --transition-bezier "$transition_bezier" 2>/dev/null
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "$wallpaper_path" > "$HYPR_DIR/.current_wallpaper"
        
        if [[ "$use_pywal" == "true" ]]; then
            apply_pywal "$wallpaper_path"
        fi
    else
        error "Error al aplicar wallpaper"
    fi
}

apply_quickshell_theme() {
    local theme_name="$1"
    
    info "Aplicando tema Quickshell..."
    
    local json_file="$THEMES_DIR/$theme_name/quickshell.json"
    
    if [[ ! -f "$json_file" ]]; then
        info "Tema Quickshell no encontrado para: $theme_name (opcional)"
        return 0
    fi
    
    mkdir -p "$HOME/.config/quickshell/themes"
    cp "$json_file" "$HOME/.config/quickshell/themes/current.json"
    
    # Quickshell recarga automáticamente con FileView — no necesita reinicio
}

apply_swayosd_theme() {
    local theme_name="$1"
    info "Aplicando tema SwayOSD..."

    local style_file="$THEMES_DIR/$theme_name/swayosd.css"
    
    if [[ -f "$style_file" ]]; then
        # Enlazar el archivo de estilo
        ln -sf "$style_file" "$SWAYOSD_DIR/style.css"
        
        # Reiniciar el servidor de SwayOSD para aplicar cambios
        killall swayosd-server 2>/dev/null
        swayosd-server &>/dev/null &
        
    else
        info "Estilo SwayOSD no encontrado para este tema"
    fi
}

# Reproducir música del tema
play_theme_music() {
    local theme_name="$1"
    local music_enabled="${THEME_MUSIC_ENABLED:-true}"
    local music_file="${THEME_MUSIC_FILE:-}"
    local music_volume="${THEME_MUSIC_VOLUME:-0.3}"
    
    # Detener música anterior si existe
    stop_theme_music
    
    if [[ "$music_enabled" != "true" ]]; then
        return 0
    fi
    
    info "Reproduciendo música del tema..."
    
    # Buscar archivo de música
    local music_path=""
    
    if [[ -n "$music_file" && -f "$THEMES_DIR/$theme_name/$music_file" ]]; then
        music_path="$THEMES_DIR/$theme_name/$music_file"
    elif [[ -f "$THEMES_DIR/$theme_name/theme.mp3" ]]; then
        music_path="$THEMES_DIR/$theme_name/theme.mp3"
    elif [[ -f "$THEMES_DIR/$theme_name/theme.ogg" ]]; then
        music_path="$THEMES_DIR/$theme_name/theme.ogg"
    elif [[ -f "$MUSIC_DIR/$theme_name.mp3" ]]; then
        music_path="$MUSIC_DIR/$theme_name.mp3"
    else
        info "Música del tema no encontrada"
        return 0
    fi
    
    # Reproducir con ffplay (silencioso, loop)
    if command -v ffplay &> /dev/null; then
        ffplay -nodisp -autoexit -loop 0 -volume $(echo "$music_volume * 100" | bc | cut -d. -f1) \
            "$music_path" &>/dev/null &
        THEME_MUSIC_PID=$!
        echo $THEME_MUSIC_PID > "$HYPR_DIR/.theme_music_pid"
        
        # Iniciar monitor para pausar cuando otro media se active
        start_media_monitor &
        
    else
        info "ffplay no está instalado (requerido para música de tema)"
    fi
}

# Detener música del tema
stop_theme_music() {
    if [[ -f "$HYPR_DIR/.theme_music_pid" ]]; then
        local pid=$(cat "$HYPR_DIR/.theme_music_pid")
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid 2>/dev/null
        fi
        rm -f "$HYPR_DIR/.theme_music_pid"
    fi
    
    # Detener monitor
    if [[ -f "$HYPR_DIR/.media_monitor_pid" ]]; then
        local monitor_pid=$(cat "$HYPR_DIR/.media_monitor_pid")
        if ps -p $monitor_pid > /dev/null 2>&1; then
            kill $monitor_pid 2>/dev/null
        fi
        rm -f "$HYPR_DIR/.media_monitor_pid"
    fi
}

# Pausar la música del tema
pause_theme_music() {
    if [[ -f "$HYPR_DIR/.theme_music_pid" ]]; then
        local pid=$(cat "$HYPR_DIR/.theme_music_pid")
        if ps -p $pid > /dev/null 2>&1; then
            kill -STOP $pid
            notify "Música del tema pausada"
        fi
    fi
}

# Reanudar la música del tema
resume_theme_music() {
    if [[ -f "$HYPR_DIR/.theme_music_pid" ]]; then
        local pid=$(cat "$HYPR_DIR/.theme_music_pid")
        if ps -p $pid > /dev/null 2>&1; then
            kill -CONT $pid
            notify "Música del tema reanudada"
        fi
    fi
}

toggle_theme_music() {
    if [[ -f "$HYPR_DIR/.theme_music_pid" ]]; then
        local pid=$(cat "$HYPR_DIR/.theme_music_pid")
        if ps -p $pid > /dev/null 2>&1; then
            # Obtener el estado del proceso (T = Pausado, S/R = Ejecutándose)
            local state=$(ps -o state= -p $pid)
            
            if [[ "$state" == "T" ]]; then
                kill -CONT $pid
                notify-send "Música" "Reanudada" -i media-playback-start
            else
                kill -STOP $pid
                notify-send "Música" "Pausada" -i media-playback-pause
            fi
        fi
    else
        info "No hay música de tema ejecutándose"
    fi
}

# Monitor de media player para pausar música del tema
start_media_monitor() {
    local monitor_script="$HYPR_DIR/.media_monitor.sh"
    
    cat > "$monitor_script" << 'EOF'
#!/bin/bash
THEME_MUSIC_PID=$(cat ~/.config/hypr/.theme_music_pid 2>/dev/null)
PAUSED=false

while true; do
    # Verificar si hay otro media player activo
    if command -v playerctl &> /dev/null; then
        # Obtener estado de todos los players EXCEPTO ffplay
        ACTIVE_PLAYERS=$(playerctl -l 2>/dev/null | grep -v "ffplay" | head -n 1)
        
        if [[ -n "$ACTIVE_PLAYERS" ]]; then
            STATUS=$(playerctl -p "$ACTIVE_PLAYERS" status 2>/dev/null)
            
            if [[ "$STATUS" == "Playing" && "$PAUSED" == "false" ]]; then
                # Pausar música del tema
                if ps -p $THEME_MUSIC_PID > /dev/null 2>&1; then
                    kill -STOP $THEME_MUSIC_PID 2>/dev/null
                    PAUSED=true
                fi
            elif [[ "$STATUS" != "Playing" && "$PAUSED" == "true" ]]; then
                # Reanudar música del tema
                if ps -p $THEME_MUSIC_PID > /dev/null 2>&1; then
                    kill -CONT $THEME_MUSIC_PID 2>/dev/null
                    PAUSED=false
                fi
            fi
        elif [[ "$PAUSED" == "true" ]]; then
            # No hay players activos, reanudar
            if ps -p $THEME_MUSIC_PID > /dev/null 2>&1; then
                kill -CONT $THEME_MUSIC_PID 2>/dev/null
                PAUSED=false
            fi
        fi
    fi
    
    sleep 2
done
EOF
    
    chmod +x "$monitor_script"
    "$monitor_script" &
    echo $! > "$HYPR_DIR/.media_monitor_pid"
}

# Aplicar configuración de Hyprland
apply_hyprland_config() {
    local theme_name="$1"
    
    info "Aplicando configuración Hyprland..."
    
    local hypr_theme_file="$THEMES_DIR/$theme_name/hyprland.conf"
    
    if [[ -f "$hypr_theme_file" ]]; then
        ln -sf "$hypr_theme_file" "$HYPR_DIR/current-theme.conf"
        hyprctl reload
    else
        info "Configuración Hyprland no encontrada (opcional)"
    fi
}

# Función principal para aplicar tema completo
apply_theme() {
    local theme_name="$1"
    
    if [[ -z "$theme_name" ]]; then
        error "Debe especificar un nombre de tema"
        return 1
    fi
    
    if [[ ! -d "$THEMES_DIR/$theme_name" ]]; then
        error "Tema no encontrado: $theme_name"
        return 1
    fi
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}    Aplicando tema: $theme_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    local theme_config="$THEMES_DIR/$theme_name/theme.conf"
    
    if [[ -f "$theme_config" ]]; then
        source "$theme_config"
    else
        error "Archivo de configuración no encontrado: $theme_config"
        return 1
    fi
    
    # Aplicar todos los componentes
    apply_gtk_theme "${GTK_THEME:-$theme_name}" "${ICON_THEME:-Papirus}" "${CURSOR_THEME:-Bibata-Modern-Ice}"
    apply_kitty_theme "${KITTY_THEME:-$theme_name}"
    apply_rofi_theme "${ROFI_THEME:-$theme_name}"
    apply_waybar_theme "${WAYBAR_THEME:-$theme_name}"
    apply_swaync_theme "${SWAYNC_THEME:-$theme_name}"
    apply_vscodium_theme "$theme_name"
    apply_spicetify_theme "$theme_name"
    apply_hyprlock_theme "$theme_name"
    apply_wallpaper "$theme_name"
    apply_hyprland_config "$theme_name"
    play_theme_music "$theme_name"
    apply_swayosd_theme "$theme_name"
    apply_quickshell_theme "$theme_name" 
    
    echo "$theme_name" > "$HYPR_DIR/.current_theme"
    
    echo ""
    notify "✨ Tema $theme_name aplicado completamente"
    echo ""
}



# ========== FUNCIONES DE WALLPAPER ==========

change_wallpaper() {
    local wallpaper="$1"
    local transition="${2:-fade}"
    local use_pywal="${3:-true}"
    
    if [[ ! -f "$wallpaper" ]]; then
        error "Wallpaper no encontrado: $wallpaper"
        return 1
    fi
    
    if ! pgrep -x awww-daemon > /dev/null; then
        info "Iniciando awww daemon..."
        awww init &
        sleep 1
    fi
    
    local cursor_pos=""
    if command -v hyprctl &> /dev/null; then
        cursor_pos=$(hyprctl cursorpos 2>/dev/null)
    fi
    
    info "Aplicando wallpaper con transición: $transition"
    
    if [[ -n "$cursor_pos" ]]; then
        awww img "$wallpaper" \
            --transition-type "$transition" \
            --transition-duration 2 \
            --transition-fps 60 \
            --transition-bezier .43,1.19,1,.4 \
            --transition-pos "$cursor_pos"
    else
        awww img "$wallpaper" \
            --transition-type "$transition" \
            --transition-duration 2 \
            --transition-fps 60 \
            --transition-bezier .43,1.19,1,.4
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "$wallpaper" > "$HYPR_DIR/.current_wallpaper"
        notify "Wallpaper cambiado: $(basename "$wallpaper")"
        
        if [[ "$use_pywal" == "true" ]]; then
            apply_pywal "$wallpaper"
        fi
    fi
}

select_wallpaper_rofi() {
    if [[ ! -d "$WALLPAPERS_DIR" ]]; then
        error "Directorio de wallpapers no encontrado: $WALLPAPERS_DIR"
        return 1
    fi
    
    local wallpapers=($(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) 2>/dev/null))
    
    if [[ ${#wallpapers[@]} -eq 0 ]]; then
        error "No se encontraron wallpapers en $WALLPAPERS_DIR"
        return 1
    fi
    
    local wallpaper_names=()
    for wp in "${wallpapers[@]}"; do
        wallpaper_names+=("$(basename "$wp")")
    done
    
    local selected=$(printf '%s\n' "${wallpaper_names[@]}" | rofi -dmenu \
        -i \
        -p "  Seleccionar Wallpaper" \
        -theme-str 'window {width: 40%;}' \
        -theme-str 'listview {lines: 10;}')
    
    if [[ -n "$selected" ]]; then
        for wp in "${wallpapers[@]}"; do
            if [[ "$(basename "$wp")" == "$selected" ]]; then
                local transitions="fade
center
outer
wave
grow
simple
random"
                
                local transition=$(echo "$transitions" | rofi -dmenu \
                    -i \
                    -p "  Transición" \
                    -theme-str 'window {width: 20%;}' \
                    -theme-str 'listview {lines: 7;}')
                
                transition=${transition:-fade}
                change_wallpaper "$wp" "$transition"
                break
            fi
        done
    fi
}

# ========== INTERFAZ DE USUARIO - ROFI ==========

select_theme_rofi() {
    local themes=($(list_themes))
    
    if [[ ${#themes[@]} -eq 0 ]]; then
        return 1
    fi
    
    local current_theme=""
    if [[ -f "$HYPR_DIR/.current_theme" ]]; then
        current_theme=$(cat "$HYPR_DIR/.current_theme")
    fi
    
    local theme_list=""
    for theme in "${themes[@]}"; do
        if [[ "$theme" == "$current_theme" ]]; then
            theme_list+="  $theme [Actual]\n"
        else
            theme_list+="  $theme\n"
        fi
    done
    
    local selected=$(echo -e "$theme_list" | rofi -dmenu \
        -i \
        -p "  Seleccionar Tema" \
        -mesg "Tema actual: ${current_theme:-Ninguno}" \
        -theme-str 'window {width: 30%;}' \
        -theme-str 'listview {lines: 8;}')
    
    if [[ -n "$selected" ]]; then
        # Limpiar el texto seleccionado
        selected=$(echo "$selected" | sed 's/^ *//' | sed 's/ *\[Actual\]$//')
        apply_theme "$selected"
    fi
}

# Menú principal Rofi
show_rofi_menu() {
    local options="  Seleccionar tema completo
  Cambiar solo wallpaper
  Listar temas disponibles
  Ver tema actual
  Crear estructura de tema
  Controlar música
  Reiniciar awww daemon
  Salir"
    
    local selected=$(echo -e "$options" | rofi -dmenu \
        -i \
        -p "Theme Switcher: " \
        -no-show-icons \
        -theme-str 'window {width: 30%;}' \
        -theme-str 'listview {lines: 8;}')
    
    case "$selected" in
        *"Seleccionar tema completo")
            select_theme_rofi
            ;;
        *"Cambiar solo wallpaper")
            select_wallpaper_rofi
            ;;
        *"Listar temas disponibles")
            local theme_text=$(list_themes | tr ' ' '\n' | sed 's/^/  /')
            echo -e "$theme_text" | rofi -dmenu -p "  Temas Disponibles" \
                -theme-str 'window {width: 30%;}' \
                -theme-str 'listview {lines: 10;}'
            ;;
        *"Ver tema actual")
            local info_text=""
            if [[ -f "$HYPR_DIR/.current_theme" ]]; then
                local current=$(cat "$HYPR_DIR/.current_theme")
                info_text+="Tema: $current\n"
            else
                info_text+="Tema: Ninguno\n"
            fi
            
            if [[ -f "$HYPR_DIR/.current_wallpaper" ]]; then
                local current_wp=$(cat "$HYPR_DIR/.current_wallpaper")
                info_text+="Wallpaper: $(basename "$current_wp")\n"
            fi
            
            if [[ -f "$HYPR_DIR/.theme_music_pid" ]]; then
                info_text+="Música: Reproduciendo"
            fi
            
            echo -e "$info_text" | rofi -dmenu -p "  Información Actual" \
                -theme-str 'window {width: 30%;}' \
                -theme-str 'listview {lines: 3;}'
            ;;
        *"Crear estructura de tema")
            local new_theme=$(rofi -dmenu -p "  Nombre del nuevo tema" \
                -theme-str 'window {width: 30%;}')
            
            if [[ -n "$new_theme" ]]; then
                create_theme_structure "$new_theme"
                notify "Tema '$new_theme' creado en $THEMES_DIR/$new_theme"
            fi
            ;;
        *"Controlar música")
            local music_options="  Pausar
  Reanudar
  Detener"
            
            local m_selected=$(echo -e "$music_options" | rofi -dmenu \
                -i \
                -p "  Control de Música" \
                -theme-str 'window {width: 20%;}' \
                -theme-str 'listview {lines: 3;}')
            
            case "$m_selected" in
                *"Pausar") pause_theme_music ;;
                *"Reanudar") resume_theme_music ;;
                *"Detener") stop_theme_music && notify "Música detenida" ;;
            esac
            ;;
        *"Reiniciar awww daemon")
            killall awww-daemon 2>/dev/null
            sleep 1
            awww init
            notify "awww daemon reiniciado"
            ;;
        *"Salir")
            exit 0
            ;;
    esac
}

# ========== MENÚ TERMINAL ==========

show_menu() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${YELLOW}           SELECTOR DE TEMAS - HYPRLAND                ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1) Seleccionar tema completo"
    echo "  2) Cambiar solo wallpaper"
    echo "  3) Listar temas disponibles"
    echo "  4) Ver tema actual"
    echo "  5) Crear estructura de tema nuevo"
    echo -e "  6) ${YELLOW}Música: [P]ausar | [R]eanudar | [S]top${NC}"
    echo "  7) Reiniciar awww daemon"
    echo "  0) Salir"
    echo ""
    read -p "Seleccione una opción: " choice
    
    case $choice in
        1)
            select_theme_rofi
            ;;
        2)
            select_wallpaper_rofi
            ;;
        3)
            echo ""
            echo "Temas disponibles:"
            list_themes | tr ' ' '\n' | sed 's/^/  - /'
            echo ""
            read -p "Presione Enter para continuar..."
            show_menu
            ;;
        4)
            echo ""
            if [[ -f "$HYPR_DIR/.current_theme" ]]; then
                current=$(cat "$HYPR_DIR/.current_theme")
                echo -e "Tema actual: ${GREEN}$current${NC}"
            else
                echo "No hay tema seleccionado"
            fi
            
            if [[ -f "$HYPR_DIR/.current_wallpaper" ]]; then
                current_wp=$(cat "$HYPR_DIR/.current_wallpaper")
                echo -e "Wallpaper actual: ${GREEN}$(basename "$current_wp")${NC}"
            fi
            
            if [[ -f "$HYPR_DIR/.theme_music_pid" ]]; then
                echo -e "Música del tema: ${GREEN}Reproduciendo${NC}"
            fi
            echo ""
            read -p "Presione Enter para continuar..."
            show_menu
            ;;
        5)
            read -p "Nombre del nuevo tema: " new_theme
            create_theme_structure "$new_theme"
            read -p "Presione Enter para continuar..."
            show_menu
            ;;
        6)
            echo -e "\nControl de música:"
            echo "p) Pausar"
            echo "r) Reanudar"
            echo "s) Detener por completo"
            read -p "Acción: " m_choice
            case $m_choice in
                p|P) pause_theme_music ;;
                r|R) resume_theme_music ;;
                s|S) stop_theme_music ; notify "Música detenida" ;;
            esac
            sleep 1
            show_menu
            ;;
        7)
            info "Reiniciando awww daemon..."
            killall awww-daemon 2>/dev/null
            sleep 1
            awww init
            notify "awww daemon reiniciado"
            sleep 2
            show_menu
            ;;
        0)
            stop_theme_music
            echo "¡Hasta luego!"
            exit 0
            ;;
        *)
            error "Opción inválida"
            sleep 1
            show_menu
            ;;
    esac
}

create_theme_structure() {
    local theme_name="$1"
    
    if [[ -z "$theme_name" ]]; then
        error "Debe especificar un nombre de tema"
        return 1
    fi
    
    local new_theme_dir="$THEMES_DIR/$theme_name"
    
    if [[ -d "$new_theme_dir" ]]; then
        error "El tema ya existe: $theme_name"
        return 1
    fi
    
    info "Creando estructura para tema: $theme_name"
    
    mkdir -p "$new_theme_dir"
    mkdir -p "$new_theme_dir/rofi"
    
    cat > "$new_theme_dir/theme.conf" << EOF
# Configuración del tema: $theme_name

# GTK
GTK_THEME="$theme_name"
ICON_THEME="Papirus-Dark"
CURSOR_THEME="Bibata-Modern-Ice"

# Kitty
KITTY_THEME="$theme_name"

# Rofi
ROFI_THEME="$theme_name"

# Waybar
WAYBAR_THEME="$theme_name"

# SwayNC
SWAYNC_THEME="$theme_name"

# VSCodium (nombre exacto del tema instalado)
VSCODIUM_THEME="One Dark Pro"

# Spicetify (Spotify)
SPICETIFY_THEME="Sleek"
SPICETIFY_SCHEME="Nord"

# Pywal - Generar colores desde wallpaper
USE_PYWAL="true"  # true o false

# Música del tema
THEME_MUSIC_ENABLED="false"       # true para activar música
THEME_MUSIC_FILE="theme.mp3"      # Nombre del archivo de audio
THEME_MUSIC_VOLUME="0.3"          # Volumen (0.0 a 1.0)

# AWWW (Wallpaper transitions)
AWWW_TRANSITION="fade"
AWWW_DURATION="2"
AWWW_FPS="60"
AWWW_BEZIER=".43,1.19,1,.4"
EOF
    
    # Crear archivo básico de Rofi
    cat > "$new_theme_dir/rofi.rasi" << 'EOF'
* {
    bg: #1e1e2e;
    bg-alt: #313244;
    fg: #cdd6f4;
    fg-alt: #9399b2;
    
    selected: #89b4fa;
    active: #a6e3a1;
    urgent: #f38ba8;
    
    border: #89b4fa;
    
    background-color: @bg;
    text-color: @fg;
}

window {
    width: 600px;
    padding: 10px;
    border: 2px;
    border-color: @border;
    border-radius: 10px;
}

mainbox {
    spacing: 10px;
    children: [inputbar, message, listview];
}

inputbar {
    padding: 10px;
    background-color: @bg-alt;
    border-radius: 5px;
    children: [prompt, entry];
}

prompt {
    padding: 0 10px 0 0;
    text-color: @selected;
}

entry {
    placeholder: "Buscar...";
    placeholder-color: @fg-alt;
}

message {
    padding: 10px;
    background-color: @bg-alt;
    border-radius: 5px;
}

listview {
    lines: 8;
    scrollbar: false;
    spacing: 5px;
}

element {
    padding: 8px;
    border-radius: 5px;
}

element selected {
    background-color: @selected;
    text-color: @bg;
}

element-text {
    background-color: inherit;
    text-color: inherit;
}
EOF
    
    # Crear archivo de colores
    cat > "$new_theme_dir/rofi/colors.rasi" << EOF
* {
    bg: #1e1e2e;
    bg-alt: #313244;
    fg: #cdd6f4;
    fg-alt: #9399b2;
    
    selected: #89b4fa;
    active: #a6e3a1;
    urgent: #f38ba8;
    
    border: #89b4fa;
}
EOF
    
    touch "$new_theme_dir/kitty.conf"
    touch "$new_theme_dir/waybar.css"
    touch "$new_theme_dir/swaync.css"
    touch "$new_theme_dir/hyprland.conf"
    touch "$new_theme_dir/hyprlock.conf"
    
    notify "✨ Estructura de tema creada en: $new_theme_dir"
    
    echo ""
    echo "Archivos creados:"
    echo "  - theme.conf (configuración principal)"
    echo "  - rofi.rasi (tema de Rofi)"
    echo "  - rofi/colors.rasi (colores de Rofi)"
    echo "  - kitty.conf (colores de terminal)"
    echo "  - waybar.css (estilo de barra)"
    echo "  - swaync.css (tema de notificaciones)"
    echo "  - hyprland.conf (configuración WM)"
    echo "  - hyprlock.conf (pantalla de bloqueo)"
    echo ""
    echo "Archivos opcionales:"
    echo "  - wallpaper.jpg/png (wallpaper del tema)"
    echo "  - theme.mp3/ogg (música del tema)"
}

# ========== INICIALIZACIÓN ==========

check_directories() {
    mkdir -p "$THEMES_DIR"
    mkdir -p "$KITTY_DIR/themes"
    mkdir -p "$ROFI_DIR"
    mkdir -p "$ROFI_DIR/themes"
    mkdir -p "$WAYBAR_DIR/styles"
    mkdir -p "$SWAYNC_DIR/styles"
    mkdir -p "$WALLPAPERS_DIR"
    mkdir -p "$VSCODIUM_DIR"
    mkdir -p "$HYPRLOCK_DIR"
    mkdir -p "$MUSIC_DIR"
    mkdir -p "$SWAYOSD_DIR"
}

check_dependencies() {
    local missing_deps=()
    
    command -v rofi &> /dev/null || missing_deps+=("rofi")
    command -v awww &> /dev/null || missing_deps+=("awww")
    command -v swaync &> /dev/null || missing_deps+=("swaync")
    command -v hyprlock &> /dev/null || missing_deps+=("hyprlock")
    command -v ffplay &> /dev/null || missing_deps+=("ffmpeg")
    command -v playerctl &> /dev/null || missing_deps+=("playerctl")
    
    command -v spicetify &> /dev/null || info "Spicetify no instalado (opcional)"
    command -v codium &> /dev/null || info "VSCodium no instalado (opcional)"
    command -v wal &> /dev/null || info "pywal no instalado (opcional)"
    command -v pywalfox &> /dev/null || info "pywalfox no instalado (opcional)"
    command -v bc &> /dev/null || info "bc no instalado (opcional, para volumen)"
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[!] Dependencias faltantes:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Instalar con: sudo pacman -S ${missing_deps[@]}"
        echo ""
    fi
}

# ========== MAIN ==========

main() {
    check_directories
    check_dependencies
    
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --wallpaper|-w)
                if [[ -n "$2" ]]; then
                    change_wallpaper "$2" "${3:-fade}"
                else
                    select_wallpaper_rofi
                fi
                ;;
            --rofi|-r)
                show_rofi_menu
                ;;
            --stop-music)
                stop_theme_music
                notify "Música del tema detenida"
                ;;
            --toggle-music)
                toggle_theme_music
                ;;
            --help|-h)
                echo "Uso: $0 [opciones] [tema]"
                echo ""
                echo "Opciones:"
                echo "  -r, --rofi                              Mostrar menú Rofi"
                echo "  -w, --wallpaper [archivo] [transición]  Cambiar wallpaper"
                echo "  --stop-music                            Detener música del tema"
                echo "  --toggle-music                          Pausar/reanudar música"
                echo "  -h, --help                              Mostrar ayuda"
                echo ""
                echo "Transiciones disponibles:"
                echo "  fade, center, outer, any, random, wave, grow, simple"
                echo ""
                echo "Ejemplos:"
                echo "  $0                    # Mostrar menú interactivo terminal"
                echo "  $0 --rofi            # Mostrar menú Rofi"
                echo "  $0 nord              # Aplicar tema 'nord'"
                echo "  $0 -w ~/wall.jpg     # Cambiar wallpaper"
                echo "  $0 --stop-music      # Detener música"
                echo ""
                echo "Keybindings sugeridos para Hyprland:"
                echo "  bind = SUPER, T, exec, $0 --rofi"
                echo "  bind = SUPER, W, exec, $0 --wallpaper"
                echo "  bind = SUPER, M, exec, $0 --toggle-music"
                ;;
            *)
                apply_theme "$1"
                ;;
        esac
    else
        show_menu
    fi
}

main "$@"