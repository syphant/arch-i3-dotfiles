#!/bin/sh
sleep 1
xrandr --output DP-2 --pos 0x0 --mode 1920x1080 --rate 60 \
       --output DP-2 --rotate right \
       --output DP-2 --scale 1x1 \
       --output DP-4 --pos 1080x0 --mode 2560x1440 --rate 165 \
       --output DP-4 --scale 1x1
