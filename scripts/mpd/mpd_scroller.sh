#!/usr/bin/env bash

# ===== НАСТРОЙКИ =====
SCROLL_LEN=25        # Длина видимой области при скроллинге
DELAY=0.3            # Скорость скроллинга (меньше = быстрее)
PADDING="   "        # Буферные пробелы для плавного скролла

# ===== ФУНКЦИИ =====
safe_mpc() {
    mpc --format "%artist% - %title%" current 2>/dev/null || echo "MPD offline"
}

get_status() {
    mpc status 2>/dev/null | grep -oP '\[playing\]|\[paused\]|\[stopped\]' || echo "offline"
}

# ===== ГЛАВНЫЙ ЦИКЛ =====
while true; do
    # Получаем текущий трек и статус с обработкой ошибок
    track=$(safe_mpc)
    status=$(get_status)

    # Определяем CSS-класс по статусу для Waybar
    case "$status" in
        "[playing]") status_class="playing" ;;
        "[paused]")  status_class="paused" ;;
        "[stopped]") status_class="stopped" ;;
        *)           status_class="offline" ;;
    esac

    # Если трек пустой или MPD не доступен
    if [ -z "$track" ] || [ "$track" = "MPD offline" ]; then
        json_output="{\"text\": \"$track\", \"class\": \"$status_class\", \"tooltip\": \"$track\"}"
        echo "$json_output"
        sleep 1
        continue
    fi
    
    # Подготавливаем текст для скроллинга
    text="${PADDING}${track}${PADDING}"
    text_len=${#text}
    
    # Если трек короче SCROLL_LEN, показываем без скролла
    if [ ${#track} -le $SCROLL_LEN ]; then
        json_output="{\"text\": \"$track\", \"class\": \"$status_class\", \"tooltip\": \"$track\"}"
        echo "$json_output"
        sleep 1
        continue
    fi
    
    # Цикл скроллинга с проверкой изменений
    while true; do
        # Проверяем изменения с обработкой ошибок
        new_track=$(safe_mpc)
        new_status=$(get_status)
        
        if [ "$new_track" != "$track" ] || [ "$new_status" != "$status" ]; then
            break
        fi
        
        # Скролл влево
        for ((i=0; i<=text_len-SCROLL_LEN; i++)); do
            json_output="{\"text\": \"${text:i:SCROLL_LEN}\", \"class\": \"$status_class\", \"tooltip\": \"$track\"}"
            echo "$json_output"
            sleep $DELAY
        done
        
        # Скролл вправо
        for ((i=text_len-SCROLL_LEN; i>=0; i--)); do
            json_output="{\"text\": \"${text:i:SCROLL_LEN}\", \"class\": \"$status_class\", \"tooltip\": \"$track\"}"
            echo "$json_output"
            sleep $DELAY
        done
        
        sleep 0.5  # Пауза между циклами
    done
done