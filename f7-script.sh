#!/bin/bash

set -e

INTERNAL=LVDS1
EXTERNAL=VGA1

show_usage() {
    cat <<END
Screen switch helper script.

Usage: $0 <command>

  commands:
    toggle
    external
    internal
    mirror

END
}

screen_external() {
    xrandr --output "$INTERNAL" --off
    xrandr --output "$EXTERNAL" --auto
}
screen_internal() {
    xrandr --output "$EXTERNAL" --off
    xrandr --output "$INTERNAL" --auto
}
screen_mirror() {
    xrandr --output "$INTERNAL" --auto
    xrandr --output "$EXTERNAL" --auto --same-as "$INTERNAL"
}

screen_toggle() {
    case "$STATE" in 
        internal)
            screen_external
            ;;
        external)
            screen_internal
            ;;
        mirror)
            screen_external
            ;;
        *)
            screen_internal
            ;;
    esac
}


screen_get_state() {
    SCREEN="$1"
    xrandr --query | grep "^$SCREEN"
    #xrandr --query | grep "^$SCREEN" | grep connected | sed 's/.*connected\s*\([^ ]\+\).*/\1/' | grep -o '[0-9]*x[0-9]*' || echo
}
is_connected() {
    echo "$1" | grep ' connected' >/dev/null && echo 1 || echo
}
is_active() {
    echo "$1" | grep connected | sed 's/.*connected\s*\([^ ]\+\).*/\1/' | grep -o '[0-9]*x[0-9]*' || echo
}

INTERNAL_STATE=$(screen_get_state "$INTERNAL")
EXTERNAL_STATE=$(screen_get_state "$EXTERNAL")

EXTERNAL_CONNECTED=$(is_connected "$EXTERNAL_STATE")

if [ -z "$EXTERNAL_CONNECTED" ] ; then
    echo "External monitor $EXTERNAL not connected." >&2
    exit 0
fi

INTERNAL_STATE=$(is_active "$INTERNAL_STATE")
EXTERNAL_STATE=$(is_active "$EXTERNAL_STATE")
if [ -z "$INTERNAL_STATE" ] ; then
    STATE="external"
elif [ -z "$EXTERNAL_STATE" ] ; then
    STATE="internal"
else
    STATE="mirror"
fi

DO="$1"
if [ -z "$DO" ] ; then
    DO="toggle"
fi

case "$DO" in
    toggle)
        screen_toggle
        ;;
    internal)
        screen_internal
        ;;
    external)
        screen_external
        ;;
    mirror)
        screen_mirror
        ;;
    *)
        show_usage >&2
        ;;
esac
