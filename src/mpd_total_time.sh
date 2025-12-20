#!/bin/bash

format_time() {
    printf "%02d:%02d" $(($1/60)) $(($1%60))
}

status=$(mpc status 2>/dev/null)

if [ $? -eq 0 ]; then
    if echo "$status" | grep -q 'playing\|paused'; then
        time_data=$(mpc status | awk '/\[/ {print $3}')
        total=$(echo "$time_data" | cut -d'/' -f2)
        total_sec=$(echo "$total" | awk -F: '{print $1*60+$2}')
        echo "{\"text\": \"$(format_time $total_sec)\", \"tooltip\": \"Total time\"}"
    else
        echo "{\"text\": \"00:00\", \"tooltip\": \"MPD idle\"}"
    fi
else
    echo "{\"text\": \"MPD Offline\", \"tooltip\": \"MPD not running\"}"
fi