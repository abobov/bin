#!/bin/bash
#
# Print current battery status.  Can be used in genmon xfce plugin.

print_sepparator=false

print_status() {
  [ $print_sepparator = true ] && printf ' '

  case "$status" in
  "Full" | "Not charging")
    return
    ;;
  "Discharging")
    status="↓"
    ;;
  "Charging")
    status="↑"
    ;;
  "Unknown")
    # Probably rich the threshold
    if [ "$(echo "$current_charge > 50" | bc -l)" == 1 ]; then
      return
    fi
    status="?"
    ;;
  *)
    status="?"
    ;;
  esac

  printf '%s %.0f%s' "$(basename "$bat")" "$current_charge" "$status"

  print_sepparator=true
}

for bat in /sys/class/power_supply/BAT?; do
  status=$(cat "$bat/status")
  energy_full=$(cat "$bat/energy_full")
  energy_now=$(cat "$bat/energy_now")
  current_charge=$(bc <<<"scale=2; $energy_now / $energy_full * 100")

  print_status
done
echo
