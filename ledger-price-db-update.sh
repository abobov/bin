#!/bin/bash
#
# Get currency exchanges rate and update a ledger price file.
#

set -e

LEDGER="$HOME/.ledgerrc"
if [[ ! -f "$LEDGER" ]] ; then
    echo "No ledger configuration file: $LEDGER" >&2
    exit 13
fi
PRICE_DB_FILE=$(sed -nE "s/^--price-db (.*)/\1/p" "$LEDGER")
PRICE_DB_FILE="${PRICE_DB_FILE/#\~/$HOME}"

xe() {
    curl -s "http://download.finance.yahoo.com/d/quotes.csv?s=$1&f=p"
}

print_rate() {
    currency="$1"
    symbol="$2"

    val=$(xe "$currency=X")

    test -n "$val" && echo P $(date +"%Y/%m/%d %H:%M:%S") $symbol $val R
}

{
    print_rate "USDRUB" "\$"
    print_rate "EURRUB" "€"
    print_rate "PLNRUB" "P"
} >> "$PRICE_DB_FILE"

