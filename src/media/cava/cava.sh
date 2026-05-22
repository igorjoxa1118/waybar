#!/usr/bin/env bash
set -euo pipefail

# --- Файлы и именованные каналы
LOCK_FILE="/tmp/cava.lock"
FIFO_FILE="/tmp/cava_fifo"

# Удаление старых файлов, чтобы избежать конфликтов при запуске
rm -f "$LOCK_FILE" "$FIFO_FILE"

# Проверка на уже запущенный экземпляр
exec 200>"$LOCK_FILE"
flock -n 200 || {
    echo "Another instance is already running. Exiting." >&2
    exit 1
}

# --- Динамическое определение активного источника
# Находим текущий "Default Sink" и формируем из него имя монитора
DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d ' ' -f3)
SOURCE_MONITOR="${DEFAULT_SINK}.monitor"

# --- Генерация временного конфига
CONFIG_FILE="$(mktemp /tmp/cava_config.XXXXXX)"
cat >"$CONFIG_FILE" << EOF
[general]
bars = 16
channels = stereo
framerate = 25
sensitivity = 50

[input]
method = pulse
source = $SOURCE_MONITOR
# source = bluez_output.F4_B6_2D_14_EB_77.1.monitor

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 5

[color]
gradient = 0

[smoothing]
integral = 40
gravity = 40
EOF

# --- Параметры звука
SOUND_THRESHOLD=0
SOUND_TIMEOUT=2
LAST_SOUND_TIME=$(date +%s)

# --- Параметры смены цвета
COLOR_CHANGE_INTERVAL=3
LAST_COLOR_UPDATE=$(date +%s)

# --- Цвет режима простоя
IDLE_COLOR="#2C3A51"

# --- Градиентная палитра Catppuccin Mocha
SATURATED_COLORS=(
    "#f5e0dc"
    "#f2cdcd"
    "#f5c2e7"
    "#e6e9c9"
    "#a6e3a1"
    "#94e2d5"
    "#89dceb"
    "#74c7ec"
    "#89b4fa"
    "#cba6f7"
)
NUM_BARS=16

# --- Инициализация текущих цветов для каждого бара
CURRENT_COLORS=()
for ((i=0; i<NUM_BARS; i++)); do
    CURRENT_COLORS[i]="${SATURATED_COLORS[RANDOM % ${#SATURATED_COLORS[@]}]}"
done

# Очистка при завершении
cleanup() {
    echo "Cleaning up..." >&2
    rm -f "$CONFIG_FILE" "$FIFO_FILE" "$LOCK_FILE"
    if [ -n "${CAVA_PID:-}" ]; then
      kill "$CAVA_PID" 2>/dev/null || true
    fi
    exit 0
}
trap cleanup EXIT

# --- Создание именованного канала
mkfifo "$FIFO_FILE"

# --- Запуск cava и цикл обработки вывода
cava -p "$CONFIG_FILE" > "$FIFO_FILE" 2>/dev/null &
CAVA_PID=$!
exec 3<>"$FIFO_FILE"

# Обработка вывода для Waybar
while IFS=';' read -u 3 -r -a BARS || [ -n "${BARS[*]}" ]; do
    NOW=$(date +%s)
    OUTPUT=""

    # Проверка наличия звука
    SOUND=false
    for h in "${BARS[@]}"; do
        if (( h > SOUND_THRESHOLD )); then
            SOUND=true
            LAST_SOUND_TIME=$NOW
            break
        fi
    done

    # обновление цветов всех баров одновременно по интервалу
    if (( NOW - LAST_COLOR_UPDATE >= COLOR_CHANGE_INTERVAL )); then
        for ((i=0; i<NUM_BARS; i++)); do
            CURRENT_COLORS[i]="${SATURATED_COLORS[RANDOM % ${#SATURATED_COLORS[@]}]}"
        done
        LAST_COLOR_UPDATE=$NOW
    fi

    # Определение режима
    if (( NOW - LAST_SOUND_TIME < SOUND_TIMEOUT )); then
        for ((i=0; i<NUM_BARS; i++)); do
            if (( BARS[i] > SOUND_THRESHOLD )); then
                OUTPUT+="<span color='${CURRENT_COLORS[i]}'>|</span>"
            else
                OUTPUT+="<span color='${IDLE_COLOR}'>|</span>"
            fi
        done
    else
        for _ in "${BARS[@]}"; do
            OUTPUT+="<span color='${IDLE_COLOR}'>|</span>"
        done
    fi

    echo "$OUTPUT" 2>/dev/null
done

# Закрытие именованного канала
exec 3>&-
wait "$CAVA_PID" 2>/dev/null

# cleanup() вызывается автоматически при завершении скрипта