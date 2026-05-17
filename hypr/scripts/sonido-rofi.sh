#!/bin/bash
# Obtiene las salidas de audio (Sinks)
options=$(wpctl status | grep -A 10 "Sinks" | grep "\[" | awk -F '.' '{print $2}' | sed 's/^[ \t]*//')

chosen=$(echo -e "$options" | rofi -dmenu -p "󰓃 Salida Audio" -theme "$HOME/.config/rofi/current-theme.rasi")

if [ -n "$chosen" ]; then
    # Extrae el ID y cambia la salida predeterminada
    id=$(wpctl status | grep "$chosen" | grep -oP '\d+' | head -n 1)
    wpctl set-default "$id"
fi