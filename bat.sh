#!/usr/bin/env bash

set -euo pipefail

ac_online=$(cat /sys/class/power_supply/AC/online)

if [ "$ac_online" = 1 ]; then
  echo "On power"
fi

for bat in /sys/class/power_supply/BAT?; do
  energy_full=$(cat "$bat/energy_full")
  energy_now=$(cat "$bat/energy_now")
  current_charge=$(bc <<<"scale=2; $energy_now / $energy_full * 100")

  printf '%s: %.0f%%\n' "$(basename "$bat")" "$current_charge"
done
