#!/bin/bash

set -e

TODAY_REMINDERS=$(rem -r -k'echo 1' | wc -l)
CAL_IMG="/usr/share/icons/Adwaita/scalable/mimetypes/x-office-calendar-symbolic.svg"

if [ -f "$CAL_IMG" ] ; then
    echo "<img>$CAL_IMG</img>"
fi
[ $TODAY_REMINDERS -gt 0 ] && echo "<txt> $TODAY_REMINDERS</txt>"
echo "<click>tkremind -m -b1 </click>"
echo "<tool>"
echo "<span font_family='monospace' size='small'>"
rem
echo
task rc.color=off genmon
echo "</span>"
echo "</tool>"
