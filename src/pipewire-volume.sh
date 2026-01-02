#!/bin/bash

volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk -F'[ .]' '{print $2 * 100}')

if [[ $(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED") ]]; then
    echo "muted"
else
    echo "VOL $volume"
fi
