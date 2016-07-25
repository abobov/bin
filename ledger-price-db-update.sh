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

usd=$(xe "USDRUB=X")
eur=$(xe "EURRUB=X")

test -n "$usd" && echo P $(date +"%Y/%m/%d %H:%M:%S") \$ $usd R >> "$PRICE_DB_FILE"
test -n "$eur" && echo P $(date +"%Y/%m/%d %H:%M:%S") €  $eur R >> "$PRICE_DB_FILE"
