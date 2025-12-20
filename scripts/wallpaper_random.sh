#!/bin/sh
is_mpvpaper_ServerExist=`ps -ef|grep -m 1 mpvpaper|grep -v "grep"|wc -l`
if [ "$is_mpvpaper_ServerExist" = "0" ]; then
	echo "mpvpaper_server not found" > /dev/null 2>&1
#	exit;
elif [ "$is_mpvpaper_ServerExist" = "1" ]; then
  killall mpvpaper
fi

is_swaybg_ServerExist=`ps -ef|grep -m 1 swww-daemon|grep -v "grep"|wc -l`
if [ "$is_swaybg_ServerExist" = "0" ]; then
	swww-daemon
	swww img $(find ~/.config/wallpapers/. -name "*.**g" | shuf -n1) &
else
	swww img $(find ~/.config/wallpapers/. -name "*.**g" | shuf -n1) &
fi

