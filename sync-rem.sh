#!/bin/sh

set -e

PREV_MONTHS=2
MONTHS=$((12 + PREV_MONTHS))
START=$(date --date "$PREV_MONTHS months ago" +%F)
chronic gcalcli --calendar remind delete --iamaexpert '*'
rem -ppp$MONTHS -b1 -m $START | rem2ics | chronic gcalcli --calendar remind import -
