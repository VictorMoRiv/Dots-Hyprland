#!/bin/bash

# 1. Pedir el texto a traducir
text=$(rofi -dmenu -p "󰗊 Traducir al Español" -config "~/.config/rofi/config.rasi")

# Si el usuario no escribió nada, salir
if [ -z "$text" ]; then
    exit 0
fi

# 2. Realizar la traducción (target language: es)
# Usamos -b (brief) para obtener solo la traducción sin diccionarios extra
translation=$(trans -b :es "$text")

# 3. Mostrar el resultado
# Si el usuario pulsa Enter sobre la traducción, se copia al portapapeles
chosen=$(echo -e "$translation\n--- Regresar ---" | rofi -dmenu -p "󱘝 Resultado" -config "~/.config/rofi/config.rasi")

if [ "$chosen" == "$translation" ]; then
    echo "$translation" | wl-copy
    notify-send "Traductor" "Copiado al portapapeles: $translation"
fi