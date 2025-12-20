#!/bin/bash

# Получаем данные о треке
ARTIST=$(mpc --format "%artist%" current 2>/dev/null || echo "Unknown Artist")
TITLE=$(mpc --format "%title%" current 2>/dev/null || echo "Unknown Title")
STATUS=$(mpc status 2>/dev/null | awk 'FNR==2 {print $1}' RS='[' FS=']' || echo "disconnected")

# Цвета из темы Catppuccin Mocha
COLOR_ARTIST="#a6e3a1"  # зеленый
COLOR_TITLE="#89b4fa"   # синий
COLOR_DISABLED="#585b70" # серый

# Формируем текст в зависимости от статуса
if [[ $STATUS == "playing" || $STATUS == "paused" ]]; then
    TEXT=""
    TOOLTIP="<span foreground='$COLOR_ARTIST'>$ARTIST</span> - <span foreground='$COLOR_TITLE'>$TITLE</span>"
else
    TEXT=""
    TOOLTIP="<span foreground='$COLOR_DISABLED'>MPD disconnected</span>"
fi

# Возвращаем JSON с Pango-разметкой
echo "{\"text\":\"$TEXT\",\"tooltip\":\"$TOOLTIP\",\"markup\":\"pango\"}"