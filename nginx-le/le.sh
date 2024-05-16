#!/bin/sh

set -ue

LE_LIVE="/etc/letsencrypt/live"
LE_WEBROOT="/var/lib/letsencrypt"

args="$*"
set --        "--agree-tos"
set -- "${@}" "--email" "\"${LE_EMAIL}\""
set -- "${@}" "--webroot"
set -- "${@}" "--webroot-path" "\"${LE_WEBROOT}\""
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
	route "$command"
}

route() {
	if [ "$1" = "self" ]; then
		self
		return
	fi

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
	exit 1
}

self() {
	mkdir -p "$LE_LIVE"
	ifs="$IFS"
	IFS=","
	for domain in $LE_DOMAINS; do
		dir="$LE_LIVE/$domain"
		mkdir "$dir"
		openssl req \
			-days 1 \
			-keyout "$dir/privkey.pem" \
			-newkey rsa:1024 \
			-out "$dir/fullchain.pem" \
			-subj "/CN=localhost" \
			-nodes \
			-x509
		cp "$dir/fullchain.pem" "$dir/chain.pem"
	done
	IFS="$ifs"
	chown -R nginx:nginx "$LE_LIVE"
}

test() {
	# shellcheck disable=SC2086
	certbot certonly --staging $options
	chown -R nginx:nginx "$LE_LIVE"
	nginx -s reload
}

prod() {
	# shellcheck disable=SC2086
	certbot certonly $options
	chown -R nginx:nginx "$LE_LIVE"
	nginx -s reload
}

job() {
	file=$(readlink -f "$0")
	dir=$(dirname "$file")
	sh="#!/bin/sh\nsu nginx -c 'LE_EMAIL=\"$LE_EMAIL\" LE_DOMAINS=\"$LE_DOMAINS\" \"$file\" renew >> \"$dir/le.log\" 2>&1'"
	file=/etc/periodic/weekly/le
	printf "%b" "$sh" > $file
	chmod +x $file
}

renew() {
	certbot renew --non-interactive
	chown -R nginx:nginx "$LE_LIVE"
	nginx -s reload
}

help() {
	echo "Usage: le.sh <command>"
	echo
	echo "Commands:"
	echo "  help   Show this help message"
	echo "  self   Generate a self-signed certificate"
	echo "  test   Obtain a test certificate"
	echo "  prod   Obtain a production certificate"
	echo "  job    Schedule a job to renew the certificate"
	echo "  renew  Renew the certificate"
}

log() {
	printf "%b" "[$(date +'%Y-%m-%d %H:%M:%S')] $1\n"
}

main "$@"
