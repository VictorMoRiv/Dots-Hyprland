#!/bin/bash
# Auto Theme Scheduler - Cambio automático de temas según la hora
# Para usar con tu theme switcher de Hyprland
# Soporta horas y minutos exactos (ej: 4:30, 16:45)

# ============ CONFIGURACIÓN ============
CONFIG_DIR="$HOME/.config"
HYPR_DIR="$CONFIG_DIR/hypr"
THEME_SWITCHER="$HYPR_DIR/scripts/theme-switcher.sh"  # Ruta a tu script de temas

# Archivo de configuración del scheduler
SCHEDULER_CONFIG="$HYPR_DIR/auto-theme.conf"

# ============ HORARIOS Y TEMAS ============
# Formato: "HH:MM" y nombre del tema a aplicar
# Puedes usar cualquier hora y minuto

# Configuración por defecto (se puede sobrescribir en auto-theme.conf)
declare -A TIME_THEMES=(
    ["07:30"]="Catppuccin-latte"
    ["12:30"]="Everforest"      # 6:00 AM - Tema de mañana
    ["16:30"]="Rose-Pine"           # 12:00 PM - Tema de día
    ["19:30"]="Catppuccin-mocha"      # 6:00 PM - Tema de tarde/noche
    ["21:30"]="Gruvbox"               # 10:00 PM - Tema nocturno
    ["23:30"]="Kanagawa"
)

# ============ COLORES PARA OUTPUT ============
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============ FUNCIONES ============

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HYPR_DIR/auto-theme.log"
}

notify() {
    echo -e "${GREEN}[✓]${NC} $1"
    notify-send "Auto Theme" "$1" -i preferences-desktop-theme
    log "INFO: $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    notify-send "Auto Theme Error" "$1" -u critical -i dialog-error
    log "ERROR: $1"
}

info() {
    echo -e "${BLUE}[i]${NC} $1"
    log "INFO: $1"
}

# Cargar configuración personalizada
load_config() {
    if [[ -f "$SCHEDULER_CONFIG" ]]; then
        info "Cargando configuración desde $SCHEDULER_CONFIG"
        source "$SCHEDULER_CONFIG"
    else
        info "Usando configuración por defecto"
    fi
}

# Convertir tiempo "HH:MM" a minutos desde medianoche
time_to_minutes() {
    local time="$1"
    local hour=$(echo "$time" | cut -d: -f1 | sed 's/^0*//')
    local minute=$(echo "$time" | cut -d: -f2 | sed 's/^0*//')
    
    # Manejar casos donde hour o minute están vacíos
    hour=${hour:-0}
    minute=${minute:-0}
    
    echo $((hour * 60 + minute))
}

# Crear archivo de configuración de ejemplo
create_config_template() {
    cat > "$SCHEDULER_CONFIG" << 'EOF'
# Configuración de Auto Theme Scheduler
# Define qué tema aplicar a cada hora del día

# Formato: TIME_THEMES["HH:MM"]="nombre_del_tema"
# Puedes usar cualquier hora y minuto

# Ejemplo de configuración para 4 periodos del día:
declare -A TIME_THEMES=(
    ["06:00"]="rosepine-dawn"      # Mañana (6:00 AM)
    ["12:00"]="rosepine"           # Mediodía (12:00 PM)
    ["18:00"]="rosepine-moon"      # Tarde (6:00 PM)
    ["22:00"]="nord"               # Noche (10:00 PM)
)

# Ejemplo con minutos específicos:
# declare -A TIME_THEMES=(
#     ["04:30"]="pre-dawn"         # Antes del amanecer
#     ["07:15"]="morning-light"    # Mañana clara
#     ["09:30"]="work-light"       # Trabajo matutino
#     ["14:00"]="afternoon"        # Tarde
#     ["16:45"]="golden-hour"      # Hora dorada
#     ["19:30"]="evening"          # Anochecer
#     ["22:00"]="night"            # Noche
#     ["00:00"]="midnight"         # Medianoche
# )

# Puedes definir tantos horarios como quieras
# El tema se mantendrá hasta el siguiente horario definido
EOF
    
    info "Archivo de configuración creado en: $SCHEDULER_CONFIG"
    info "Edítalo para personalizar tus temas por hora"
}

# Obtener el tema que debe aplicarse en el momento actual
get_current_theme() {
    local current_minutes=$(date +%-H)
    current_minutes=$((current_minutes * 60 + $(date +%-M)))
    
    local selected_theme=""
    local selected_minutes=-1
    
    # Buscar el horario más cercano pero menor o igual al actual
    for time_key in "${!TIME_THEMES[@]}"; do
        local time_minutes=$(time_to_minutes "$time_key")
        
        if [[ $time_minutes -le $current_minutes ]] && [[ $time_minutes -gt $selected_minutes ]]; then
            selected_minutes=$time_minutes
            selected_theme="${TIME_THEMES[$time_key]}"
        fi
    done
    
    # Si no encontramos ningún horario menor, usar el último del día anterior
    if [[ -z "$selected_theme" ]]; then
        for time_key in "${!TIME_THEMES[@]}"; do
            local time_minutes=$(time_to_minutes "$time_key")
            if [[ $time_minutes -gt $selected_minutes ]]; then
                selected_minutes=$time_minutes
                selected_theme="${TIME_THEMES[$time_key]}"
            fi
        done
    fi
    
    echo "$selected_theme"
}

# Aplicar el tema usando el theme switcher
apply_theme() {
    local theme_name="$1"
    
    if [[ ! -f "$THEME_SWITCHER" ]]; then
        error "Theme switcher no encontrado en: $THEME_SWITCHER"
        return 1
    fi
    
    if [[ ! -x "$THEME_SWITCHER" ]]; then
        chmod +x "$THEME_SWITCHER"
    fi
    
    info "Aplicando tema: $theme_name"
    
    # Ejecutar el theme switcher
    "$THEME_SWITCHER" "$theme_name"
    
    if [[ $? -eq 0 ]]; then
        notify "✨ Tema cambiado automáticamente: $theme_name"
        echo "$theme_name" > "$HYPR_DIR/.auto_theme_current"
        echo "$(date +%s)" > "$HYPR_DIR/.auto_theme_last_change"
        return 0
    else
        error "Error al aplicar tema: $theme_name"
        return 1
    fi
}

# Verificar si necesitamos cambiar el tema
check_and_apply() {
    local current_theme=$(get_current_theme)
    local last_theme=""
    
    if [[ -f "$HYPR_DIR/.auto_theme_current" ]]; then
        last_theme=$(cat "$HYPR_DIR/.auto_theme_current")
    fi
    
    if [[ "$current_theme" != "$last_theme" ]]; then
        info "Detectado cambio de periodo. Nuevo tema: $current_theme"
        apply_theme "$current_theme"
    else
        log "Tema actual es correcto: $current_theme"
    fi
}

# Verificar si es momento de cambiar tema
should_change_theme() {
    local current_time=$(date +%H:%M)
    local current_minutes=$(time_to_minutes "$current_time")
    
    # Verificar si algún horario configurado coincide con el actual
    for time_key in "${!TIME_THEMES[@]}"; do
        local scheduled_minutes=$(time_to_minutes "$time_key")
        
        # Si estamos dentro del minuto del cambio programado
        if [[ $current_minutes -eq $scheduled_minutes ]]; then
            return 0  # Sí, es momento de cambiar
        fi
    done
    
    return 1  # No es momento de cambiar
}

# Modo daemon - monitorear continuamente
run_daemon() {
    echo $$ > "$HYPR_DIR/.auto_theme_pid"
    while true; do
        check_and_apply
        sleep 60
    done
}

# Detener el daemon
stop_daemon() {
    if [[ -f "$HYPR_DIR/.auto_theme_pid" ]]; then
        local pid=$(cat "$HYPR_DIR/.auto_theme_pid")
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid
            rm -f "$HYPR_DIR/.auto_theme_pid"
            notify "Auto Theme Scheduler detenido"
            info "Daemon detenido (PID: $pid)"
        else
            error "El proceso no está en ejecución"
            rm -f "$HYPR_DIR/.auto_theme_pid"
        fi
    else
        error "No hay daemon en ejecución"
    fi
}

# Verificar estado del daemon
check_status() {
    if [[ -f "$HYPR_DIR/.auto_theme_pid" ]]; then
        local pid=$(cat "$HYPR_DIR/.auto_theme_pid")
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Auto Theme Scheduler está en ejecución${NC} (PID: $pid)"
            
            if [[ -f "$HYPR_DIR/.auto_theme_current" ]]; then
                local current=$(cat "$HYPR_DIR/.auto_theme_current")
                echo -e "  Tema actual: ${BLUE}$current${NC}"
            fi
            
            if [[ -f "$HYPR_DIR/.auto_theme_last_change" ]]; then
                local last_change=$(cat "$HYPR_DIR/.auto_theme_last_change")
                local now=$(date +%s)
                local diff=$((now - last_change))
                local hours=$((diff / 3600))
                local minutes=$(((diff % 3600) / 60))
                echo -e "  Último cambio: hace ${hours}h ${minutes}m"
            fi
            
            # Mostrar próximo cambio
            local next_change=$(get_next_theme_change)
            if [[ -n "$next_change" ]]; then
                echo -e "  Próximo cambio: ${YELLOW}$next_change${NC}"
            fi
            
            return 0
        else
            echo -e "${RED}✗ El daemon no está en ejecución${NC} (PID obsoleto encontrado)"
            rm -f "$HYPR_DIR/.auto_theme_pid"
            return 1
        fi
    else
        echo -e "${YELLOW}○ Auto Theme Scheduler no está en ejecución${NC}"
        return 1
    fi
}

# Obtener información del próximo cambio de tema
get_next_theme_change() {
    local current_minutes=$(date +%-H)
    current_minutes=$((current_minutes * 60 + $(date +%-M)))
    
    local next_time=""
    local next_theme=""
    local min_diff=9999
    
    for time_key in "${!TIME_THEMES[@]}"; do
        local time_minutes=$(time_to_minutes "$time_key")
        local diff=0
        
        if [[ $time_minutes -gt $current_minutes ]]; then
            diff=$((time_minutes - current_minutes))
        else
            # Es para el día siguiente
            diff=$((1440 - current_minutes + time_minutes))
        fi
        
        if [[ $diff -lt $min_diff ]]; then
            min_diff=$diff
            next_time="$time_key"
            next_theme="${TIME_THEMES[$time_key]}"
        fi
    done
    
    if [[ -n "$next_time" ]]; then
        local hours=$((min_diff / 60))
        local mins=$((min_diff % 60))
        echo "$next_time → $next_theme (en ${hours}h ${mins}m)"
    fi
}

# Mostrar próximos cambios de tema
show_schedule() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}      Programación de Temas por Hora${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo ""
    
    local current_minutes=$(date +%-H)
    current_minutes=$((current_minutes * 60 + $(date +%-M)))
    
    # Ordenar tiempos
    local sorted_times=($(for time in "${!TIME_THEMES[@]}"; do echo "$time"; done | sort))
    
    # Encontrar cuál es el tema activo actual
    local active_theme=$(get_current_theme)
    
    for time_key in "${sorted_times[@]}"; do
        local theme="${TIME_THEMES[$time_key]}"
        local time_minutes=$(time_to_minutes "$time_key")
        local marker=""
        
        # Determinar si este es el tema activo
        if [[ "$theme" == "$active_theme" ]]; then
            # Verificar que estamos en el rango de este tema
            local is_active=1
            
            # Buscar el siguiente horario
            for next_time in "${sorted_times[@]}"; do
                local next_minutes=$(time_to_minutes "$next_time")
                
                if [[ $next_minutes -gt $time_minutes ]]; then
                    if [[ $current_minutes -ge $time_minutes ]] && [[ $current_minutes -lt $next_minutes ]]; then
                        marker="${GREEN}◄ ACTIVO${NC}"
                        is_active=0
                        break
                    fi
                fi
            done
            
            # Si no encontramos siguiente, verificar si es el último del día
            if [[ $is_active -eq 1 ]] && [[ $current_minutes -ge $time_minutes ]]; then
                marker="${GREEN}◄ ACTIVO${NC}"
            fi
        fi
        
        printf "  %s  →  %-25s  %b\n" "$time_key" "$theme" "$marker"
    done
    
    echo ""
    
    # Mostrar próximo cambio
    local next_info=$(get_next_theme_change)
    if [[ -n "$next_info" ]]; then
        echo -e "${YELLOW}Próximo cambio:${NC} $next_info"
        echo ""
    fi
}

# Probar tema manual sin afectar el scheduler
test_theme() {
    local theme_name="$1"
    
    if [[ -z "$theme_name" ]]; then
        error "Debe especificar un nombre de tema para probar"
        return 1
    fi
    
    info "Probando tema: $theme_name (no afecta el scheduler automático)"
    
    if [[ -f "$THEME_SWITCHER" ]]; then
        "$THEME_SWITCHER" "$theme_name"
    else
        error "Theme switcher no encontrado"
    fi
}

# Mostrar ayuda
show_help() {
    cat << EOF
${BLUE}════════════════════════════════════════════════════════════${NC}
${YELLOW}  Auto Theme Scheduler - Cambio automático por hora${NC}
${BLUE}════════════════════════════════════════════════════════════${NC}

${GREEN}USO:${NC}
  $0 [comando] [opciones]

${GREEN}COMANDOS:${NC}
  start                 Iniciar el scheduler en modo daemon
  stop                  Detener el scheduler
  restart               Reiniciar el scheduler
  status                Ver estado del scheduler
  now                   Aplicar el tema correspondiente a la hora actual
  schedule              Mostrar programación de temas
  test <tema>           Probar un tema manualmente
  config                Crear/editar archivo de configuración
  help                  Mostrar esta ayuda

${GREEN}EJEMPLOS:${NC}
  $0 start              # Iniciar scheduler
  $0 status             # Ver si está corriendo
  $0 schedule           # Ver qué tema se aplica a cada hora
  $0 now                # Aplicar tema actual inmediatamente
  $0 test rosepine      # Probar tema sin afectar scheduler
  $0 config             # Crear archivo de configuración

${GREEN}CONFIGURACIÓN:${NC}
  Archivo: ${BLUE}$SCHEDULER_CONFIG${NC}
  
  Edita este archivo para definir qué tema se aplica a cada hora.
  ${YELLOW}Ahora soporta minutos específicos:${NC}
  
  ${YELLOW}declare -A TIME_THEMES=(
      ["04:30"]="pre-dawn"         # 4:30 AM
      ["06:00"]="rosepine-dawn"    # 6:00 AM
      ["12:00"]="rosepine"         # 12:00 PM
      ["16:45"]="golden-hour"      # 4:45 PM
      ["18:00"]="rosepine-moon"    # 6:00 PM
      ["22:00"]="nord"             # 10:00 PM
  )${NC}

${GREEN}AUTOSTART (Hyprland):${NC}
  Agrega a tu hyprland.conf:
  ${YELLOW}exec-once = $0 start${NC}

${GREEN}KEYBINDINGS SUGERIDOS:${NC}
  ${YELLOW}bind = SUPER SHIFT, T, exec, $0 now${NC}
  ${YELLOW}bind = SUPER SHIFT, S, exec, $0 schedule${NC}

${GREEN}LOGS:${NC}
  Los registros se guardan en: ${BLUE}$HYPR_DIR/auto-theme.log${NC}

EOF
}

# ============ MAIN ============

main() {
    load_config
    
    case "${1:-}" in
        start)
            if check_status >/dev/null 2>&1; then
                error "El scheduler ya está en ejecución"
                exit 1
            fi
            # Ejecutar como daemon desconectado de la terminal
            nohup "$0" --daemon-mode >/dev/null 2>&1 &
            sleep 1
            check_status
            ;;
        
        --daemon-mode)
            # Modo interno para ejecutar como daemon
            run_daemon
            ;;
        
        stop)
            stop_daemon
            ;;
        
        restart)
            info "Reiniciando Auto Theme Scheduler..."
            stop_daemon
            sleep 1
            $0 start
            ;;
        
        status)
            check_status
            ;;
        
        now)
            info "Aplicando tema para la hora actual..."
            check_and_apply
            ;;
        
        schedule)
            show_schedule
            ;;
        
        test)
            test_theme "$2"
            ;;
        
        config)
            if [[ -f "$SCHEDULER_CONFIG" ]]; then
                info "Abriendo configuración existente..."
                ${EDITOR:-nano} "$SCHEDULER_CONFIG"
            else
                create_config_template
                info "Editando nueva configuración..."
                ${EDITOR:-nano} "$SCHEDULER_CONFIG"
            fi
            ;;
        
        help|--help|-h|"")
            show_help
            ;;
        
        *)
            error "Comando desconocido: $1"
            echo "Use '$0 help' para ver los comandos disponibles"
            exit 1
            ;;
    esac
}

main "$@"