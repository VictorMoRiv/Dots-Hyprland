#!/bin/bash

# Importa tu tema Rose Pine Dawn
THEME="$HOME/.config/rofi/config.rasi"

# Obtener lista de redes Wi-Fi
wifi_list=$(nmcli --fields "SECURITY,SSID,BARS" device wifi list | sed 1d | sed 's/^  *//' | awk -F'  +' '{printf "%s %s\n", $3, $2}')

# Mostrar menú con Rofi
chosen_network=$(echo -e "$wifi_list" | rofi -dmenu -i -p "󰖩  Wi-Fi " -theme "$THEME" -no-show-icons)

# Si se seleccionó una red, pedir contraseña
if [ -n "$chosen_network" ]; then
    ssid=$(echo "$chosen_network" | awk '{print $2}')
    pass=$(rofi -dmenu -p "󰷦  Password para $ssid: " -theme "$THEME" -password -no-show-icons)
    
    if [ -n "$pass" ]; then
        nmcli device wifi connect "$ssid" password "$pass"
    fi
fi