#!/bin/bash

set -e

outputs=($(xrandr --query | awk '/^[^ ]+ connected / { print $1 }'))

echo ${#outputs[@]}
echo ${outputs[1]}

exit 0

INTERNAL=$(xrandr --query | awk '/^\w+-?[0-9] connected /{ print $1; exit }')
EXTERNAL=$(xrandr --query | awk '/^\w+-?[0-9] connected /{print $1; exit }')

if [ -z "$INTERNAL" ] ; then
    echo "WARN: No internal screen."
fi
if [ -z "$EXTERNAL" ] ; then
    echo "WARN: No external screen."
fi

echo $INTERNAL $EXTERNAL

return 0

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
    xrandr --output "$INTERNAL" --auto
    xrandr --output "$EXTERNAL" --off
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
    if [ -z "$SCREEN" ] ; then
        echo ""
        return
    fi
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
    screen_internal
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
