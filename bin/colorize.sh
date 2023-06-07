#!/usr/bin/env bash

#Color Foreground Background
#black 30 40
#red 31 41
#green 32 42
#yellow 33 43
#blue 34 44
#magenta 35 45
#cyan 36 46
#white 37 47

FGBLACK=$(printf "\\033[1;30m")
FGRED=$(printf "\\033[1;31m")
FGGREEN=$(printf "\\033[1;32m")
FGYELLOW=$(printf "\\033[1;33m")
FGBLUE=$(printf "\\033[1;34m")
FGMAGENTA=$(printf "\\033[1;35m")
FGCYAN=$(printf "\\033[1;36m")
FGWHITE=$(printf "\\033[1;37m")

BGBLACK=$(printf "\\033[1;40m")
BGRED=$(printf "\\033[1;41m")
BGGREEN=$(printf "\\033[1;42m")
BGYELLOW=$(printf "\\033[1;43m")
BGBLUE=$(printf "\\033[1;44m")
BGMAGENTA=$(printf "\\033[1;45m")
BGCYAN=$(printf "\\033[1;46m")
BGWHITE=$(printf "\\033[1;47m")

BOLD=$(printf "\\033[1;1m")

COLEND=$(printf "\\033[0m")

cat | sed \
    -e "s@~FGBLACK~@$FGBLACK@g" \
    -e "s@~FGRED~@$FGRED@g" \
    -e "s@~FGGREEN~@$FGGREEN@g" \
    -e "s@~FGYELLOW~@$FGYELLOW@g" \
    -e "s@~FGBLUE~@$FGBLUE@g" \
    -e "s@~FGMAGENTA~@$FGMAGENTA@g" \
    -e "s@~FGCYAN~@$FGCYAN@g" \
    -e "s@~FGWHITE~@$FGWHITE@g" \
    -e "s@~BGBLACK~@$BGBLACK@g" \
    -e "s@~BGRED~@$BGRED@g" \
    -e "s@~BGGREEN~@$BGGREEN@g" \
    -e "s@~BGYELLOW~@$BGYELLOW@g" \
    -e "s@~BGBLUE~@$BGBLUE@g" \
    -e "s@~BGMAGENTA~@$BGMAGENTA@g" \
    -e "s@~BGCYAN~@$BGCYAN@g" \
    -e "s@~BGWHITE~@$BGWHITE@g" \
    -e "s@~BOLD~@$BOLD@g" \
    -e "s@~~@$COLEND@g"
