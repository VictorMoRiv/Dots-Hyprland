#!/bin/bash

# Ruta a tu configuración dinámica
THEME="$HOME/.config/rofi/config.rasi"

# Función para obtener el estado del Bluetooth
get_status() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        echo "󰂯 On"
    else
        echo "󰂲 Off"
    fi
}

# Lista de opciones principales
options="󰂯 Encender\n󰂲 Apagar\n󰂰 Conectar Dispositivo\n󰂱 Desconectar\n󱘝 Limpiar Dispositivos"

chosen=$(echo -e "$options" | rofi -dmenu -p "Bluetooth ($(get_status))" -theme-str 'inputbar { spacing: 20px; }' -theme-str 'prompt { padding: 0 15px 0 5px; }' -no-show-icons)

case "$chosen" in
    *"Encender") bluetoothctl power on ;;
    *"Apagar") bluetoothctl power off ;;
    *"Conectar"*)
        # Lista dispositivos emparejados para conectar
        devices=$(bluetoothctl devices | cut -d ' ' -f 3-)
        device_name=$(echo -e "$devices" | rofi -dmenu -p "Conectar a:" -no-show-icons)
        mac=$(bluetoothctl devices | grep "$device_name" | awk '{print $2}')
        bluetoothctl connect "$mac"
        ;;
    *"Desconectar")
        # Lista dispositivos conectados para desconectar
        devices=$(bluetoothctl info | grep "Name" | cut -d ' ' -f 2-)
        bluetoothctl disconnect
        ;;
esac