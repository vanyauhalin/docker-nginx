#!/bin/sh

set -u

args="$*"

set --        "--agree-tos"
set -- "${@}" "--email" "\"${LE_EMAIL}\""
set -- "${@}" "--webroot"
set -- "${@}" "--webroot-path" "/var/lib/letsencrypt"
set -- "${@}" "--domains" "\"${LE_DOMAINS}\""
options="${*}"

set -- "$args"

main() {
	command=${1-""}

	if [ "$command" = "" ]; then
		help
		exit 1
	fi

	if [ "$command" = "help" ]; then
		help
		exit
	fi

	log "Executing the \"$command\" command with: $options"

	if ! route "$command"; then
		log "Failed to execute the \"$command\" command"
		exit 1
	fi

	log "Successfully executed the \"$command\" command"
}

route() {
	if [ "$1" = "test" ]; then
		test
		return
	fi

	if [ "$1" = "prod" ]; then
		prod
		return
	fi

	if [ "$1" = "job" ]; then
		job
		return
	fi

	if [ "$1" = "renew" ]; then
		renew
		return
	fi

	log "Unknown command: $1"
	return 1
}

test() {
	# shellcheck disable=SC2086
	certbot certonly --staging $options
	nginx -s reload
}

prod() {
	# shellcheck disable=SC2086
	certbot certonly $options
	nginx -s reload
}

job() {
	file=$(readlink -f "$0")
	dir=$(dirname "$file")
	sh="#!/bin/sh\nLE_EMAIL=\"$LE_EMAIL\" LE_DOMAINS=\"$LE_DOMAINS\" \"$file\" renew >> \"$dir/le.log\" 2>&1\n"
	file=/etc/periodic/weekly/le
	printf "%b" "$sh" > $file
	chmod +x $file
}

renew() {
	certbot renew --non-interactive
	nginx -s reload
}

help() {
	echo "Usage: le.sh <command>"
	echo
	echo "Commands:"
	echo "  help   Show this help message"
	echo "  test   Obtain a test certificate"
	echo "  prod   Obtain a production certificate"
	echo "  job    Schedule a job to renew the certificate"
	echo "  renew  Renew the certificate"
}

log() {
	printf "%b" "[$(date +'%Y-%m-%d %H:%M:%S')] $1\n"
}

main "$@"
