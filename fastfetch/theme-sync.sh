#!/bin/bash

# Detectar el tema actual de kitty
kitty_theme=$(grep "^include " ~/.config/kitty/kitty.conf | awk '{print $2}')

# Configurar colores según el tema
if [[ "$kitty_theme" == *"dark"* ]] || [[ "$kitty_theme" == *"night"* ]]; then
    # Tema oscuro
    fastfetch --logo-color-1 magenta --logo-color-2 blue --color blue
else
    # Tema claro
    fastfetch --logo-color-1 red --logo-color-2 yellow --color yellow
fi
