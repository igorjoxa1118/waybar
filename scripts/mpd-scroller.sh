#!/bin/bash

# Конфиг
LENGTH=40          # Максимальная длина строки
SCROLL_SPEED=1     # Сколько символов сдвигать за шаг
CACHE="/tmp/waybar_mpd_scroll"

# Получаем текущий трек
track=$(mpc -f "%artist% - %title%" current)

# Если трек пустой – очищаем кэш и выходим
if [[ -z "$track" ]]; then
    echo ""
    rm -f "$CACHE"
    exit 0
fi

# Если трек изменился – сбрасываем позицию
if [[ ! -f "$CACHE" ]] || [[ "$(head -n1 "$CACHE")" != "$track" ]]; then
    echo "$track" > "$CACHE"
    echo 0 >> "$CACHE"  # позиция
fi

# Загружаем данные
pos=$(tail -n1 "$CACHE")

# Если трек длинный – скроллим
if (( ${#track} > LENGTH )); then
    # Добавляем "бесконечную ленту" с разделителем
    scroll_text="$track   -   $track"
    output="${scroll_text:pos:LENGTH}"

    # Увеличиваем позицию
    pos=$((pos+SCROLL_SPEED))
    if (( pos > ${#track} + 3 )); then
        pos=0
    fi
    echo "$track" > "$CACHE"
    echo "$pos" >> "$CACHE"
else
    output="$track"
fi

# Вывод в формате для waybar
echo "$output"