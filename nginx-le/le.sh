#!/bin/sh

set -ue

main() {
	cmd=${1-""}
	if [ "$cmd" = "" ];        then help;    return 1; fi
	if [ "$cmd" = "help" ];    then help;    return;   fi
	log "Executing the '$cmd' command"
	if [ "$cmd" = "options" ]; then options; return;   fi
	if [ "$cmd" = "self" ];    then self;    return;   fi
	if [ "$cmd" = "test" ];    then test;    return;   fi
	if [ "$cmd" = "prod" ];    then prod;    return;   fi
	if [ "$cmd" = "job" ];     then job;     return;   fi
	if [ "$cmd" = "renew" ];   then renew;   return;   fi
	log "Unknown the command '$cmd'"
	return 1
}

options() {
	s="--agree-tos"
	s="${s} --config-dir ${LE_CONFIG_DIR}"
	s="${s} --work-dir ${LE_WORK_DIR}"
	s="${s} --logs-dir ${LE_LOGS_DIR}"
	s="${s} --email ${LE_EMAIL}"
	s="${s} --webroot"

	ifs="$IFS"
	IFS=","
	for domain in $LE_DOMAINS; do
		s="${s} --webroot-path ${LE_WEBROOT_DIR}/${domain}"
		s="${s} --domain ${domain}"
	done
	IFS="$ifs"

	echo "$s"
}

self() {
	live_dir="$LE_CONFIG_DIR/live"
	mkdir -p "$live_dir"

	ifs="$IFS"
	IFS=","
	for domain in $LE_DOMAINS; do
		dir="$live_dir/$domain"
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

	chown -R nginx:nginx "$LE_CONFIG_DIR"
}

test() {
	# shellcheck disable=SC2046
	certbot certonly --staging $(options)
	chown -R nginx:nginx "$LE_CONFIG_DIR"
	nginx -s reload
}

prod() {
	# shellcheck disable=SC2046
	certbot certonly $(options)
	chown -R nginx:nginx "$LE_CONFIG_DIR"
	nginx -s reload
}

job() {
	file=$(readlink -f "$0")
	dir=$(dirname "$file")
	sh="#!/bin/sh\n"
	sh="$sh\"$file\" options >> \"$dir/le.log\" 2>&1\n"
	sh="$sh\"$file\" renew >> \"$dir/le.log\" 2>&1\n"
	file=/etc/periodic/weekly/le
	printf "%b" "$sh" > $file
	chmod +x $file
}

renew() {
	certbot renew --non-interactive
	chown -R nginx:nginx "$LE_CONFIG_DIR"
	nginx -s reload
}

help() {
	echo "Usage: le.sh <command>"
	echo
	echo "Subcommands:"
	echo "  help     Show this help message"
	echo "  options  Show the letsencrypt options"
	echo "  self     Generate a self-signed certificate"
	echo "  test     Obtain a test certificate"
	echo "  prod     Obtain a production certificate"
	echo "  job      Schedule a job to renew the certificate"
	echo "  renew    Renew the certificate"
}

log() {
	printf "%b" "[$(date +'%Y-%m-%d %H:%M:%S')] $1\n"
}

main "$@"
