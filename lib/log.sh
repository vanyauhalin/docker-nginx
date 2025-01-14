#!/bin/sh

set -ue

# shellcheck source=lib/color.sh
. "$LIB_DIR/color.sh"

log() {
	r="$1"

	d=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
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
