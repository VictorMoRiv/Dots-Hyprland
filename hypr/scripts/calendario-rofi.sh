#!/bin/bash

THEME="$HOME/.config/rofi/current-theme.rasi"
MONTH=$(date +%m)
YEAR=$(date +%Y)

while true; do
    curr_day=$(date +%e | sed 's/ //g')
    real_month=$(date +%m)
    real_year=$(date +%Y)
    
    # 1. Generar el texto del calendario (dentro del bucle para que cambie)
    if [ "$MONTH" -eq "$real_month" ] && [ "$YEAR" -eq "$real_year" ]; then
        cal_text=$(cal $MONTH $YEAR | sed "s/\b$curr_day\b/($curr_day)/")
    else
        cal_text=$(cal $MONTH $YEAR)
    fi

    # 2. Definir el menú completo con saltos de línea (\n) para que sean filas separadas
    # Usamos saltos de línea para que cada opción sea un bloque ancho en Rofi
    menu_text="$cal_text\n────────────────────────────\n󰁔 Mes Siguiente\n󰁍 Mes Anterior\n󰑐 Hoy\n󰈆 Salir"

    # 3. Lanzar Rofi
    selection=$(echo -e "$menu_text" | rofi -dmenu \
        -p "󰸗 $YEAR" \
        -theme "$THEME" \
        -no-show-icons \
        -theme-str 'window { width: 600px; }' \
        -theme-str 'listview { lines: 13; }' \
        -theme-str 'element-text { horizontal-align: 0.5; }' \
        -theme-str 'inputbar { spacing: 25px; }' \
        -theme-str 'prompt { padding: 0 20px 0 5px; }')

    # 4. Lógica de navegación
    case "$selection" in
        *"Siguiente"*)
            MONTH=$((10#$MONTH + 1)) # Usamos 10# para evitar errores con números como 08/09
            if [ $MONTH -gt 12 ]; then MONTH=1; YEAR=$((YEAR + 1)); fi
            ;;
        *"Anterior"*)
            MONTH=$((10#$MONTH - 1))
            if [ $MONTH -lt 1 ]; then MONTH=12; YEAR=$((YEAR - 1)); fi
            ;;
        *"Hoy"*)
            MONTH=$(date +%m)
            YEAR=$(date +%Y)
            ;;
        *)
            # Si se cierra Rofi o se elige Salir
            break
            ;;
    esac
done