#!/bin/bash
#
# Get currency exchanges rate and update a ledger price file.
#
# Read commodities from file in format: COMMODITY SYMBOL (ex.: EURUSD $)

set -e

LEDGER_COMMODITIES="$HOME/.ledger-commodities"
if [ ! -f "$LEDGER_COMMODITIES" ] ; then
    echo "No ledger commodities files: $LEDGER_COMMODITIES"
    exit 1
fi
LEDGER="$HOME/.ledgerrc"
if [[ ! -f "$LEDGER" ]] ; then
    echo "No ledger configuration file: $LEDGER" >&2
    exit 13
fi
PRICE_DB_FILE=$(sed -nE "s/^--price-db (.*)/\1/p" "$LEDGER")
PRICE_DB_FILE="${PRICE_DB_FILE/#\~/$HOME}"

print_rate() {
    currency="$1"
    symbol="$2"

    val=$(xe "$currency=X")

    [[ $val =~ ^[0-9]+\.[0-9]+$ ]] && echo P $(date +"%Y/%m/%d %H:%M:%S") $symbol $val R
}

{
    cat "$LEDGER_COMMODITIES" | while read commodity symbol ; do
        print_rate "$commodity" "$symbol"
    done
} >> "$PRICE_DB_FILE"

