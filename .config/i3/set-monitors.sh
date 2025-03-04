#!/bin/sh
sleep 1
xrandr --output DP-4 --pos 0x0 --mode 1920x1080 --rate 60 \
       --output DP-2 --pos 1920x0 --mode 2560x1440 --rate 144 \
       --output DP-0 --pos 4480x0 --mode 1920x1080 --rate 60
sleep 1
feh --bg-fill --randomize ~/backgrounds/*
picom
xsetroot -solid black
xset s on
xset s 600 1200
xset s noblank