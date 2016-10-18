#!/bin/bash

set -e

help() {
    echo "Print TTS card balance."
    echo
    echo "First argument should be card number (10 or 19 digits)."
}

if [[ $1 =~ ^([0-9]{10}|[0-9]{19})$ ]] ; then
    CARD_NUMBER=$1
else
    help
    exit 1
fi

hash=($(echo -n $(date +%d.%m.%Y).$CARD_NUMBER | md5sum))

url=$(printf "%s?numberCard=%s&h=%s&hi=1&tf=json" "http://oao-tts.ru/services/lnt/infoBalansCard.php" $CARD_NUMBER $hash)

bal=$(curl --silent "$url" | jq ".balance | tonumber")
echo "Balance: $bal"
