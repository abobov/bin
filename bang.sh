#!/bin/sh

set -e

FILE=/usr/share/orage/sounds/Spo.wav

which notify-send >/dev/null 2>&1 && notify-send "Task done"
[ -f "$FILE" ] && aplay --quiet "$FILE"
