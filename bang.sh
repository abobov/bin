#!/bin/sh

set -e

FILE=/usr/share/orage/sounds/Spo.wav

if [ ! -f "$FILE" ] ; then
    echo "No sound file: $FILE"
    exit 1
fi

aplay --quiet "$FILE"
