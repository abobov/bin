#!/bin/bash

set -e

MAXTEMP=30

TEMP=$(/usr/sbin/ipmi-sensors -r 5 | tail -n 1 | cut -d '|' -f 4 | tr -d ' ')

SP_1800=0x06
SP_2000=0x09
SP_3000=0x1a
SP_9000=0x46

SP=$SP_1800

if [[ $TEMP > $MAXTEMP ]] ; then
    # Set auto speed
    /usr/bin/ipmitool raw 0x30 0x30 0x01 0x01
else
    # Enable edit
    /usr/bin/ipmitool raw 0x30 0x30 0x01 0x00
    # Set speed 2K
    /usr/bin/ipmitool raw 0x30 0x30 0x02 0xff $SP
fi

