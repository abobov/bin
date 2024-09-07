#!/usr/bin/env bash
# Open given systemd unit in editor.

set -euo pipefail

usage() {
  echo "Usage: ${0##*/} [OPTIONS] unit-name" >&2
  exit 1
}

get_unit_path() {
  path=$(systemctl show -P FragmentPath "$@")
  if [ -z "$path" ]; then
    echo "Unit file not found" >&2
    exit 2
  fi
  echo "$path"
}

is_user_unit() {
  [ "${1##"$HOME"/}" == "$1" ]
}

main() {
  [ $# -eq 0 ] && usage

  path=$(get_unit_path "$@")
  if is_user_unit "$path"; then
    sudo -e "$path"
  else
    "${EDITOR:-vim}" "$path"
  fi
}

main "$@"
