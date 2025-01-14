#!/bin/sh

set -ue

# shellcheck source=lib/color.sh
. "$LIB_DIR/color.sh"

log() {
	r="$1"

	# https://unix.stackexchange.com/questions/167968/date-in-milliseconds-on-openwrt-on-arduino-yun/#answer-362748
	d=$(date -u "+%FT$(nmeter -d0 "%3t" | head -n1)Z")
	l=$(echo "$r" | cut -d" " -f1)
	m=$(echo "$r" | cut -d" " -f2-)

	p=$(color_dim "$d")

	case "$l" in
	ERROR)
		p="$p $(color_red "$l")"
		;;
	INFO)
		p="$p $(color_green "$l") "
		;;
	esac

	p="$p $m"

	printf "%b" "$p\n"
}
