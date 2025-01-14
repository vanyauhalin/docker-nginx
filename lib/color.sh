#!/bin/sh

# The color.sh is a simplified version of the JavaScript picocolors library.
# https://github.com/alexeyraspopov/picocolors/

set -ue

: "${FORCE_COLOR:=0}"
: "${NO_COLOR:=0}"
: "${TERM:="xterm"}"

color_init() {
	if color_is_supported; then
		color_dim() {
			color_format '\033[2m' '\033[22m' '\033[22m\033[2m' "$1"
		}

		color_red() {
			color_format '\033[31m' '\033[39m' '' "$1"
		}

		color_green() {
			color_format '\033[32m' '\033[39m' '' "$1"
		}
	else
		color_dim() {
			echo "$1"
		}

		color_red() {
			echo "$1"
		}

		color_green() {
			echo "$1"
		}
	fi
}

color_is_supported() {
	[ -n "$FORCE_COLOR" ] || {
		[ -z "$NO_COLOR" ] && [ "$TERM" != "dumb" ] && [ -t 1 ]
	}
}

color_format() {
	open="$1"
	close="$2"
	replace="${3:-$open}"
	input="$4"

	case "$input" in
	*"$close"*)
		echo "$open$(echo "$input" | sed "s#$close#$replace#g")$close"
		;;
	*)
		echo "$open$input$close"
		;;
	esac
}

color_init
