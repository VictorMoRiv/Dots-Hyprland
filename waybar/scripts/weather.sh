#!/bin/bash

# Configuración para Monterrey, Nuevo León
CITY="Monterrey"
COUNTRY="MX"
UNITS="metric"  # Para Celsius
LANG="es"

# Tu API Key de OpenWeatherMap
API_KEY="d4cfa5aaa15177b8755882f8d98a0e26"

# URL de la API
URL="http://api.openweathermap.org/data/2.5/weather?q=${CITY},${COUNTRY}&appid=${API_KEY}&units=${UNITS}&lang=${LANG}"

# Obtener datos del clima
weather=$(curl -sf "$URL")

if [ -n "$weather" ]; then
    temp=$(echo "$weather" | jq -r ".main.temp" | cut -d "." -f 1)
    feels_like=$(echo "$weather" | jq -r ".main.feels_like" | cut -d "." -f 1)
    condition=$(echo "$weather" | jq -r ".weather[0].description")
    humidity=$(echo "$weather" | jq -r ".main.humidity")
    
    # Iconos según condición climática
    weather_id=$(echo "$weather" | jq -r ".weather[0].id")
    
    if [ "$weather_id" -lt 300 ]; then
        icon="⛈️"  # Tormenta
    elif [ "$weather_id" -lt 400 ]; then
        icon="🌧️"  # Llovizna
    elif [ "$weather_id" -lt 600 ]; then
        icon="🌧️"  # Lluvia
    elif [ "$weather_id" -lt 700 ]; then
        icon="❄️"  # Nieve
    elif [ "$weather_id" -lt 800 ]; then
        icon="🌫️"  # Niebla/Neblina
    elif [ "$weather_id" -eq 800 ]; then
        icon="☀️"  # Despejado
    elif [ "$weather_id" -lt 900 ]; then
        icon="☁️"  # Nublado
    else
        icon="🌡️"  # Otro
    fi
    
    # Formato de salida para Waybar
    echo "{\"text\":\"$icon $temp°C\", \"tooltip\":\"$condition\\nSensación: $feels_like°C\\nHumedad: $humidity%\"}"
else
    echo "{\"text\":\"❌\", \"tooltip\":\"Error al obtener clima\"}"
fi