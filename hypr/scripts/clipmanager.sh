#!/bin/bash

# 1. Mostramos la lista completa en Rofi
# Cliphist necesita el ID para decodificar correctamente
selected=$(cliphist list | rofi -dmenu -p "󱘝   Clipboard" -config "~/.config/rofi/config.rasi")

# 2. Si se seleccionó algo, lo enviamos directamente a decode
if [ -n "$selected" ]; then
    echo "$selected" | cliphist decode | wl-copy
fi