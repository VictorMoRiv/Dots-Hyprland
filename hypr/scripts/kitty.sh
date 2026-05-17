#!/bin/bash

# Nombre del workspace especial para kitty
WORKSPACE="special:kitty"

# Verificar si kitty ya existe en el scratchpad
windows=$(hyprctl clients -j | jq -r ".[] | select(.workspace.name == \"$WORKSPACE\") | .address")

if [ -z "$windows" ]; then
    # Si kitty no existe, crearlo en el workspace especial
else
    # Si kitty existe, mostrar/ocultar el workspace especial
    hyprctl dispatch togglespecialworkspace kitty
fi