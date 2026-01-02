#!/bin/bash

# Устанавливаем локаль, чтобы избежать ошибок с десятичными разделителями (точки вместо запятых)
LC_NUMERIC="C"

# Автоматическое определение сетевого интерфейса ---
# Находим самый активный сетевой интерфейс (с наибольшей скоростью передачи данных)
PRIMARY_NET=$(ip -o route get 1 2>/dev/null | awk '{print $5; exit}') # Например wlan0 для wi-fi скти.
SECONDARY_NET=$(ip -o link show | awk -F': ' '{print $2}' | grep -E 'en|wlan|eth' | head -n1) # Например enp59s0 для проводной сети.

INTERFACE="$PRIMARY_NET"

# Если активный интерфейс не найден, выводим ошибку и выходим
if [[ -z "$INTERFACE" ]]; then
    echo "Не найден активный сетевой интерфейс."
    exit 1
fi

# Путь к файлу для хранения предыдущих показаний
LOG_FILE="/tmp/waybar_net_speed_log_$INTERFACE"

# Проверяем, существует ли файл с логами. Если нет, создаем его с нулевыми значениями.
if [[ ! -f "$LOG_FILE" ]]; then
    echo "0 0" > "$LOG_FILE"
fi

# Получаем текущие показания
current_rx_bytes=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null)
current_tx_bytes=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null)

# Если файл или интерфейс недоступен, выводим ошибку и выходим
if [[ -z "$current_rx_bytes" || -z "$current_tx_bytes" ]]; then
    echo "Неверный интерфейс"
    exit 1
fi

# Получаем предыдущие показания из файла
read -r prev_rx_bytes prev_tx_bytes < "$LOG_FILE"

# Сохраняем текущие показания для следующего запуска
echo "$current_rx_bytes $current_tx_bytes" > "$LOG_FILE"

# Вычисляем разницу (скорость в байтах)
rx_diff=$((current_rx_bytes - prev_rx_bytes))
tx_diff=$((current_tx_bytes - prev_tx_bytes))

# --- Пункт 6: Использование 'awk' вместо 'bc' ---
# Переводим в удобный формат (KiB/s или MiB/s)
# Скачивание
rx_output=$(awk -v diff=$rx_diff 'BEGIN {
    if (diff >= 1048576) {
        printf "%.1f MiB/s", diff / 1048576
    } else {
        printf "%.1f KiB/s", diff / 1024
    }
}')

# Загрузка
tx_output=$(awk -v diff=$tx_diff 'BEGIN {
    if (diff >= 1048576) {
        printf "%.1f MiB/s", diff / 1048576
    } else {
        printf "%.1f KiB/s", diff / 1024
    }
}')

# Выводим результат в формате для Waybar
# printf "<span color='#b4befe'></span> <span color='#cba6f7'>%s</span>  <span color='#b4befe'></span> <span color='#cba6f7'>%s</span>" "$rx_output" "$tx_output"
printf "<span color='#fab387'></span> <span color='#cdd6f4'>%s</span>" "$rx_output"