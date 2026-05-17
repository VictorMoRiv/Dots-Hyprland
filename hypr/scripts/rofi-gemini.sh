 #!/bin/bash

# Configuración
API_KEY="AIzaSyBetlDBxObG0ga8mljH1c4OO5OtYcsmYEQ"
MODEL="gemini-1.5-flash" # La versión flash es más rápida y ligera

# 1. Obtener la pregunta mediante Rofi
PROMPT=$(echo "" | rofi -dmenu -p "Pregunta a Gemini:" -config ~/.config/rofi/config.rasi)

# Si el prompt está vacío o se cancela, salir
[ -z "$PROMPT" ] && exit 0

# 2. Petición a la API (Silenciosa y ligera)
RESPONSE=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}" \
    -H 'Content-Type: application/json' \
    -d '{
      "contents": [{
        "parts":[{"text": "'"${PROMPT}"'"}]
      }]
    }')

# 3. Extraer la respuesta usando jq
RESULT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text')

# 4. Mostrar el resultado
# Usamos un segundo Rofi solo para mostrar el texto, o puedes usar un notificador
echo "$RESULT" | rofi -dmenu -p "Respuesta:" -config ~/.config/rofi/config.rasi #!/bin/bash

# Configuración
API_KEY="AIzaSyBetlDBxObG0ga8mljH1c4OO5OtYcsmYEQ"
MODEL="gemini-1.5-flash" # La versión flash es más rápida y ligera

# 1. Obtener la pregunta mediante Rofi
PROMPT=$(echo "" | rofi -dmenu -p "Pregunta a Gemini:" -config ~/.config/rofi/config.rasi)

# Si el prompt está vacío o se cancela, salir
[ -z "$PROMPT" ] && exit 0

# 2. Petición a la API (Silenciosa y ligera)
RESPONSE=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}" \
    -H 'Content-Type: application/json' \
    -d '{
      "contents": [{
        "parts":[{"text": "'"${PROMPT}"'"}]
      }]
    }')

# 3. Extraer la respuesta usando jq
RESULT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text')

# 4. Mostrar el resultado
# Usamos un segundo Rofi solo para mostrar el texto, o puedes usar un notificador
echo "$RESULT" | rofi -dmenu -p "Respuesta:" -config ~/.config/rofi/config.rasi
