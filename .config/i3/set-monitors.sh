#!/bin/sh
sleep 1
xrandr --output DP-2 --pos 0x0 --mode 1920x1080 --rate 60 \
       --output DP-2 --rotate right \
       --output DP-4 --pos 1080x0 --mode 2560x1440 --rate 165 \
sleep 1
feh --bg-fill --randomize ~/backgrounds/*
picom
xsetroot -solid black
xset s on
xset s noblank
xset -dpms
xset s 300
