#!/bin/sh

set -ue

: "${NG_ENABLED:=1}"

NG_NGINX_DIR="/etc/nginx"

NG_NGINX_CONF_FILE="$NG_NGINX_DIR/nginx.conf"
NG_NGINX_TEMPLATE_CONF_FILE="$NG_NGINX_DIR/nginx.conf.template"

ng_help() {
	echo "Usage: ng <subcommand>"
	echo
	echo "Subcommands:"
	echo "  help          Shows this help message"
	echo "  render        Renders the Nginx config from the template"
	echo
	echo "Environment variables:"
	echo "  NG_ENABLED             Whether ng is enabled"
}

main() {
	if [ "$NG_ENABLED" -ne 1 ]; then
		return
	fi

	case "${1:-}" in
	"")
		ng_help
		return 1
		;;
	"help")
		ng_help
		;;
	"render")
		ng_render
		;;
	*)
		ng_help
		return 1
		;;
	esac
}

ng_render() {
	if [ -f "$NG_NGINX_TEMPLATE_CONF_FILE" ]; then
		vars=$(env | grep -o '^NGINX_[^=]*' | sed 's/^/${/;s/$/}/' | tr '\n' ' ')
		envsubst "$vars" < "$NG_NGINX_TEMPLATE_CONF_FILE" > "$NG_NGINX_CONF_FILE"
	fi
}

main "$@"
