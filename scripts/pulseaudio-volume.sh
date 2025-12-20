#!/bin/bash

volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'yes|no')

if [[ "$muted" == "yes" ]]; then
    echo '{"text": " muted", "class": "muted"}'
else
    if [[ "$volume" -lt 30 ]]; then
        icon=""
    elif [[ "$volume" -lt 70 ]]; then
        icon=""
    else
        icon=""
    fi
    echo '{"text": "'"$icon VOL $volume%"'", "class": "unmuted"}'
fi
