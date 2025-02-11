#!/bin/sh
set -u -e

prog=${0##/*/}

reterr() {
    printf '%s\n' "$prog: $2" >&2
    return "$1"
}

usage() {
    cat >&2 <<EOF
usage: $prog [-t subsys/device] [-rlhV] [[+|-]val|toggle]
EOF
}

proghelp() {
    usage 2>&1
    cat <<EOF
options:
  -t subsys/device  target, default: backlight/auto
  -r                display and handle values in raw
  -l                list targets
  -h                print help
  -V                print version
  [+|-]val          add, subtract or set brightness with val
  toggle            toggle brightness as 0 or 1
EOF
}

act=_
raw=0
target=backlight/auto
while getopts t:rlhV0123456789 opt; do
    case $opt in
    t) target=$OPTARG;;
    r) raw=1;;
    l) act=list;;
    h) proghelp; exit;;
    V) echo "l1light v1.1.0"; exit;;
    [0-9]) OPTIND=$((OPTIND - 1)) break;;
    *) usage; exit 1;;
    esac
done

shift $((OPTIND - 1))
if [ $# -gt 1 ]; then
    usage
    exit 1
fi

if [ $act = list ]; then
    for subsys in backlight leds; do
        [ -e /sys/class/$subsys ] || continue
        echo $subsys/auto
        ls -A1q /sys/class/$subsys | grep -q . || continue
        printf '%s\n' /sys/class/$subsys/* | sed 's|^.*/\(.*/.*\)|\1|'
    done
    exit
fi

case $target in
*/*/*|"") usage; exit 1;;
*/*);;
*) usage; exit 1;;
esac

subsys=${target%/*}
devname=${target#*/}
if [ "${subsys:+.}${devname:+.}" != .. ]; then
    usage
    exit 1
fi

if [ "$devname" = auto ]; then
    [ -z "${XDG_SEAT+.}" ] && reterr 1 "no seat being managed"

    path=
    for path in "/sys/class/$subsys"/*; do
        props=`udevadm info -q property "$path" && echo .` ||
            reterr $? "cannot retrieve device properties"
        devseat=`printf %s "${props%.}" | sed -n 's/^ID_SEAT=\(.*\)/\1/p' || :`
        [ "${devseat:-seat0}" = "$XDG_SEAT" ] && break
        path=
    done

    [ -z "$path" ] && reterr 1 "no device available"
    devname=${path##/*/}
else
    path=/sys/class/$subsys/$devname
fi

valpath=$path/brightness
maxpath=$path/max_brightness

if [ -z "${1+.}" ]; then
    if [ $raw = 1 ]; then
        cat "$valpath" || reterr $? "cannot print raw value"
    else
        setp='getline val; getline max; p = val/max * 100'
        printp='print int(p) + !!(p%1)'
        awk "BEGIN {$setp; $printp}" "$valpath" "$maxpath" ||
            reterr $? "cannot print percentage"
    fi
    exit
fi

[ "$1" != toggle ] && case ${1#[+-]} in
*[!0-9]*|"") usage; exit 1;;
esac

case $1 in
toggle)
    val=`cat "$valpath"` || reterr $? "cannot toggle value"
    [ "$val" -gt 0 ] && val=0 || val=1;;
[+-]*)
    if [ $raw = 1 ]; then
        orig=`cat "$valpath"` || reterr $? "cannot add raw value"
        val=$((orig + $1))
    else
        setp='getline orig; getline max; p = orig/max * 100'
        setv="$setp; v = int(max/100 * (int(p) + !!(p%1) + val))"
        printv='print v < 0 ? 0 : (v > max ? max : v)'
        val=`awk -v val=$1 "BEGIN {$setv; $printv}" "$valpath" "$maxpath"` ||
            reterr $? "cannot add percentage"
    fi;;
*)
    aprog='BEGIN {getline max; print int(max / 100 * val)}'
    [ $raw = 1 ] && val=$1 || val=`awk -v val=$1 "$aprog" "$maxpath"` ||
        reterr $? "cannot convert percentage";;
esac

dbus-send --system --print-reply=literal --dest=org.freedesktop.login1 \
    "/org/freedesktop/login1/session/$XDG_SESSION_ID" \
    org.freedesktop.login1.Session.SetBrightness \
    string:"$subsys" string:"$devname" uint32:"$val" ||
{
    reterr $? "cannot set value"
}
