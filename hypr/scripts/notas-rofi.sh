#!/bin/bash

NOTES_FILE="$HOME/Documentos/Notas/.notas.txt"
THEME="$HOME/.config/rofi/current-theme.rasi"

touch "$NOTES_FILE"

while true; do
    # Mostramos las notas (las más nuevas arriba con tac)
    options="󰔓   Nueva Nota\n󰎚   Limpiar Todo\n────────────────────────────\n$(tac "$NOTES_FILE")"

    chosen=$(echo -e "$options" | rofi -dmenu -p "󰎚   Notas" \
        -theme "$THEME" \
        -no-show-icons \
        -theme-str 'window { width: 650px; }' \
        -theme-str 'listview { lines: 11; }' \
        -theme-str 'element-text { horizontal-align: 0; }' \
        -theme-str 'inputbar { spacing: 10px; }' \
        -theme-str 'prompt { padding: 0 0px 0 0px; }')

    case "$chosen" in
        "") exit ;;
        "󰔓   Nueva Nota")
            new_note=$(rofi -dmenu -p "󰏫 Escribir:" -theme "$THEME" -theme-str 'window { width: 1000px; } inputbar {height:1000px;}')
            if [ -n "$new_note" ]; then
                echo "$(date '+%d/%m %H:%M') - $new_note" >> "$NOTES_FILE"
            fi
            ;;
        "󰎚   Limpiar Todo")
            > "$NOTES_FILE"
            ;;
        "────────────────────────────"|*)
            if [ -z "$chosen" ] || [ "$chosen" == "────────────────────────────" ]; then continue; fi
            
            # Submenú para la nota seleccionada
            action=$(echo -e "󰅍 Copiar\n󰆴 Borrar" | rofi -dmenu -p "Acción:" -theme "$THEME" -theme-str 'window { width: 300px; }' -theme-str 'listview { lines: 2; }')
            
            if [ "$action" == "󰅍 Copiar" ]; then
                echo "$chosen" | wl-copy
                break
            elif [ "$action" == "󰆴 Borrar" ]; then
                sed -i "/$chosen/d" "$NOTES_FILE"
            fi
            ;;
    esac
done