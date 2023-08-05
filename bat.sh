#!/bin/bash

ac_online=$(cat /sys/class/power_supply/AC/online)

if [ "x$ac_online" = "x1" ] ; then
    echo "On power"
fi

for bat in /sys/class/power_supply/BAT? ; do
    status=$(cat "$bat/status")
    energy_full=$(cat "$bat/energy_full")
    energy_now=$(cat "$bat/energy_now")
    current_charge=$(bc <<< "scale=2; $energy_now / $energy_full * 100")

    printf '%s: %.0f%%\n' $(basename $bat) $current_charge
done
