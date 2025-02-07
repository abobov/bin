#!/usr/bin/env bash
# Add host to RouterOS address list.
#

set -euo pipefail

LIST_NAME="through-vpn"
ROUTER_HOST="riga"

usage() {
  cat <<EOF
Usage: ${0##*/} [-t|-n|-h] name...

Name could be a domain name or URL.

Options:
  -h    print this help
  -t    timeout value (ex: 1m, 8h)
  -n    dry run, just print commands
EOF
}

extract_domain() {
  cat <<EOF | python3
from urllib.parse import urlparse

url = urlparse(r'$1')
print(url.hostname or '$1')
EOF
}

create_router_commands() {
  local timeout="$1"
  shift
  for name in "$@"; do
    domain=$(extract_domain "$name")
    echo "/ip firewall address-list add address=$domain list=$LIST_NAME timeout=$timeout"
  done
}

main() {
  local timeout=
  local dryrun=0
  while getopts ":nt:" opt; do
    case "${opt}" in
    t)
      timeout="${OPTARG}"
      ;;
    n)
      dryrun=1
      ;;
    *)
      usage
      exit
      ;;
    esac
  done
  shift $((OPTIND - 1))

  if [ $# -eq 0 ]; then
    echo 'First argument must be domain or URL'
    exit 1
  elif [ $dryrun -eq 0 ]; then
    create_router_commands "$timeout" "$@" | ssh "$ROUTER_HOST"
  else
    create_router_commands "$timeout" "$@"
  fi
}

main "$@"
