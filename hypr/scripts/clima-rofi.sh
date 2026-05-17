#!/bin/bash

THEME="$HOME/.config/rofi/current-theme.rasi"

# Obtiene el clima en formato corto (Ciudad: Estado, Temp)
# Sustituye 'TuCiudad' por tu ubicación real o déjalo vacío para detección automática
weather_data=$(curl -s "wttr.in/?format=%l:+%C+%t\n%h+Humedad\n%w+Viento\n%m+Fase+Lunar")

# Lanzar Rofi para mostrar la información
echo -e "$weather_data" | rofi -dmenu -p "󰖐 Clima" \
    -theme "$THEME" \
    -no-show-icons \
    -theme-str 'window { width: 500px; }' \
    -theme-str 'listview { lines: 4; }' \
    -theme-str 'inputbar { spacing: 25px; }' \
    -theme-str 'prompt { padding: 0 20px 0 5px; }'