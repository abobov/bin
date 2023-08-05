#!/bin/sh
#
# Add host to through-vpn address list.
#

if [ $# -eq 0 ] ; then
    echo 'First argument must be host name.'
    exit 1
fi

comment=$(date +%F)

ssh riga "/ip firewall address-list add address=$1 list=through-vpn comment=\"$comment\""
