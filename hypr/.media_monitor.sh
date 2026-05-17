#!/bin/bash
THEME_MUSIC_PID=$(cat ~/.config/hypr/.theme_music_pid 2>/dev/null)
PAUSED=false

while true; do
    # Verificar si hay otro media player activo
    if command -v playerctl &> /dev/null; then
        # Obtener estado de todos los players EXCEPTO ffplay
        ACTIVE_PLAYERS=$(playerctl -l 2>/dev/null | grep -v "ffplay" | head -n 1)
        
        if [[ -n "$ACTIVE_PLAYERS" ]]; then
            STATUS=$(playerctl -p "$ACTIVE_PLAYERS" status 2>/dev/null)
            
            if [[ "$STATUS" == "Playing" && "$PAUSED" == "false" ]]; then
                # Pausar música del tema
                if ps -p $THEME_MUSIC_PID > /dev/null 2>&1; then
                    kill -STOP $THEME_MUSIC_PID 2>/dev/null
                    PAUSED=true
                fi
            elif [[ "$STATUS" != "Playing" && "$PAUSED" == "true" ]]; then
                # Reanudar música del tema
                if ps -p $THEME_MUSIC_PID > /dev/null 2>&1; then
                    kill -CONT $THEME_MUSIC_PID 2>/dev/null
                    PAUSED=false
                fi
            fi
        elif [[ "$PAUSED" == "true" ]]; then
            # No hay players activos, reanudar
            if ps -p $THEME_MUSIC_PID > /dev/null 2>&1; then
                kill -CONT $THEME_MUSIC_PID 2>/dev/null
                PAUSED=false
            fi
        fi
    fi
    
    sleep 2
done
