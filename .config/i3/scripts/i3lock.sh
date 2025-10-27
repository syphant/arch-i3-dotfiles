#!/bin/sh

CLEAR='#00000000'
WHITE='#ffffffff'
RED='#ff5555ff'
GRAY='#333333ff'
BLACK='#000000ff'

i3lock \
--insidever-color=$CLEAR     \
--ringver-color=$BLACK       \
--insidewrong-color=$CLEAR   \
--ringwrong-color=$RED       \
--inside-color=$CLEAR        \
--ring-color=$WHITE          \
--line-color=$CLEAR          \
--separator-color=$WHITE     \
--verif-color=$WHITE         \
--wrong-color=$WHITE         \
--time-color=$WHITE          \
--date-color=$WHITE          \
--layout-color=$WHITE        \
--keyhl-color=$BLACK         \
--bshl-color=$RED            \
--color=000000ff             \
--indicator                  \
--font="JetBrainsMono Nerd Font"