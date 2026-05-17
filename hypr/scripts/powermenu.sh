#!/bin/bash

THEME="$HOME/.config/rofi/current-theme.rasi"

# Opciones con iconos
options="󰐥 Apagar\n󰑐 Reiniciar\n󰤄 Suspender\n󰍃 Cerrar Sesión"

chosen=$(echo -e "$options" | rofi -dmenu -p "󰐥 Sistema" \
    -theme "$THEME" \
    -no-show-icons \
    -theme-str 'window { width: 400px; }' \
    -theme-str 'listview { lines: 4; }' \
    -theme-str 'inputbar { spacing: 25px; }' \
    -theme-str 'prompt { padding: 0 20px 0 5px; }')

case "$chosen" in
    *"Apagar")
        systemctl poweroff ;;
    *"Reiniciar")
        systemctl reboot ;;
    *"Suspender")
        systemctl suspend ;;
    *"Cerrar Sesión")
        hyprctl dispatch exit ;;
esac