#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Modified for Hyprland/Wayland
#
## Rofi   : Power Menu

# Текущая тема (проверьте правильность пути)
dir="$HOME/.config/waybar/src/rofi/powermenu/type-4/"
theme='style-5'

# Команды
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Опции (иконки из шрифта Feather/Nerd Fonts)
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
yes=''
no=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Goodbye ${USER}" \
		-mesg "Uptime: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

# Confirmation CMD
confirm_cmd() {
	rofi -dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme "${dir}/shared/confirm.rasi"
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			# Ставим музыку на паузу и выключаем звук через PipeWire (wpctl)
			mpc -q pause
			wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			# Нативная команда выхода для Hyprland
			hyprctl dispatch exit
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $lock)
		# Приоритет для hyprlock, затем swaylock
		if [[ -x '/usr/bin/hyprlock' ]]; then
			hyprlock
		elif [[ -x '/usr/bin/swaylock' ]]; then
			swaylock
		fi
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac