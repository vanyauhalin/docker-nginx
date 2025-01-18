#!/bin/sh

set -ue

# shellcheck source=lib/log.sh
. "$LIB_DIR/log.sh"

: "${CF_ENABLED:=1}"
: "${CF_CRON:="0	3	*	*	6"}"
: "${CF_DAYS:=90}" # 7 30 90 365 730 1095 5475
: "${CF_DOMAINS:=""}"
: "${CF_TYPE:="origin-rsa"}" # origin-rsa origin-ecc keyless-certificate
: "${CF_API_TOKEN:=""}"
: "${CF_HEALTHCHECKS_URL:=""}"

CF_CRON_ENTRY="$CF_CRON	cf -p trigger"
CF_THRESHOLD_DAYS=30

CF_CLOUDFLARE_CONFIG_DIR="/etc/cloudflare"
CF_NGINX_CONFIG_DIR="/etc/nginx"
CF_NGINX_SNIPPETS_DIR="$CF_NGINX_CONFIG_DIR/snippets"
CF_NGINX_SSL_DIR="$CF_NGINX_CONFIG_DIR/ssl"
CF_LOGS_DIR="/var/log"

CF_CA_CERT_BASE="ca-cert.pem"
CF_CERT_BASE="cert.pem"
CF_ID_BASE="id.txt"

CF_SSL_CLIENT_CERTIFICATE_BASE="ssl-client-certificate.conf"

CF_SELF_LOGS_DIR="$CF_LOGS_DIR/cf"
CF_SELF_LOG_FILE="$CF_SELF_LOGS_DIR/output.log"

cf_help() {
	echo "Usage: cf [options] <subcommand>"
	echo "       cf obtain [options]"
	echo "       cf renew [options]"
	echo "       cf logs [options]"
	echo
	echo "Options:"
	echo "  -p            Pipes the output to the log file"
	echo
	echo "Subcommands:"
	echo "  help          Shows this help message"
	echo "  obtain        Obtains certificates"
	echo "  schedule      Schedules certificate renewal"
	echo "  trigger       Triggers scheduled operations"
	echo "  renew         Renews certificates"
	echo "  logs          Shows the log file"
	echo "  env           Shows the environment variables"
	echo
	echo "Obtain options:"
	echo "  -g            Guards the existence of certificates"
	echo "  -s            Skips rendering, testing Nginx configuration and reloading Nginx"
	echo
	echo "Renew options:"
	echo "  -f            Forces the renewal of certificates"
	echo
	echo "Logs options:"
	echo "  -f            Follows the log file"
	echo "  -n <lines>    Shows the last n lines of the log file"
	echo
	echo "Environment variables:"
	echo "  CF_ENABLED             Whether cf is enabled"
	echo "  CF_CRON                Cron schedule for certificate renewal"
	echo "  CF_DAYS                Validity period for certificates when obtaining new ones"
	echo "                         (can be 7, 30, 90, 365, 730, 1095, 5475)"
	echo "  CF_DOMAINS             Comma-separated list of domains to obtain certificates for"
	echo "  CF_TYPE                Type of certificate to obtain"
	echo "                         (can be origin-rsa, origin-ecc, keyless-certificate)"
	echo "  CF_API_TOKEN           Cloudflare API token"
	echo "  CF_HEALTHCHECKS_URL    URL to Healthchecks check"
}

main() {
	if [ "$CF_ENABLED" -ne 1 ]; then
		return
	fi

	cmd=""
	pipe=0

	guard=0
	skip=0

	follow=0
	lines=0

	while [ $# -gt 0 ]; do
		if [ "$1" = "-p" ] && [ "$cmd" = "" ]; then
			pipe=1
			shift
			continue
		fi

		if [ "$1" = "help" ] && [ "$cmd" = "" ]; then
			cmd="help"
			shift
			continue
		fi

		if [ "$1" = "obtain" ] && [ "$cmd" = "" ]; then
			cmd="obtain"
			shift
			continue
		fi

		if [ "$1" = "-g" ] && [ "$cmd" = "obtain" ]; then
			guard=1
			shift
			continue
		fi

		if [ "$1" = "-s" ] && [ "$cmd" = "obtain" ]; then
			skip=1
			shift
			continue
		fi

		if [ "$1" = "schedule" ] && [ "$cmd" = "" ]; then
			cmd="schedule"
			shift
			continue
		fi

		if [ "$1" = "trigger" ] && [ "$cmd" = "" ]; then
			cmd="trigger"
			shift
			continue
		fi

		if [ "$1" = "renew" ] && [ "$cmd" = "" ]; then
			cmd="renew"
			shift
			continue
		fi

		if [ "$1" = "-f" ] && [ "$cmd" = "renew" ]; then
			force=1
			shift
			continue
		fi

		if [ "$1" = "logs" ] && [ "$cmd" = "" ]; then
			cmd="logs"
			shift
			continue
		fi

		if [ "$1" = "-f" ] && [ "$cmd" = "logs" ]; then
			follow=1
			shift
			continue
		fi

		if [ "$1" = "-n" ] && [ "$cmd" = "logs" ]; then
			lines="$2"
			shift 2
			continue
		fi

		if [ "$1" = "env" ] && [ "$cmd" = "" ]; then
			cmd="env"
			shift
			continue
		fi

		log "ERROR Unknown argument '$1'"
		return 1
	done

	if [ "$pipe" -eq 1 ]; then
		if [ ! -d "$CF_SELF_LOGS_DIR" ]; then
			mkdir -p "$CF_SELF_LOGS_DIR"
		fi
		if [ ! -f "$CF_SELF_LOG_FILE" ]; then
			touch "$CF_SELF_LOG_FILE"
		fi
	fi

	case "$cmd" in
	"")
		cf_help
		return 1
		;;
	"help")
		cf_help
		;;
	"obtain")
		if [ "$pipe" -eq 1 ]; then
			cf_obtain "$guard" "$skip" >> "$CF_SELF_LOG_FILE" 2>&1
		else
			cf_obtain "$guard" "$skip"
		fi
		;;
	"schedule")
		if [ "$pipe" -eq 1 ]; then
			cf_schedule >> "$CF_SELF_LOG_FILE" 2>&1
		else
			cf_schedule
		fi
		;;
	"trigger")
		if [ "$pipe" -eq 1 ]; then
			cf_trigger >> "$CF_SELF_LOG_FILE" 2>&1
		else
			cf_trigger
		fi
		;;
	"renew")
		if [ "$pipe" -eq 1 ]; then
			cf_renew "$force" >> "$CF_SELF_LOG_FILE" 2>&1
		else
			cf_renew "$force"
		fi
		;;
	"logs")
		cf_logs "$follow" "$lines"
		;;
	"env")
		cf_env
		;;
	esac
}

cf_obtain() {
	status=0

	guard=$1
	skip=$2

	log "INFO Obtaining $CF_TYPE certificates"

	ifs="$IFS"
	IFS=","

	for domain in $CF_DOMAINS; do
		if [ "$guard" -eq 0 ]; then
			log "INFO Skipping the existence check of the certificate for domain '$domain'"
		else
			log "INFO Checking the existence of the certificate for domain '$domain'"

			if
				[ -d "$CF_NGINX_SSL_DIR/$domain" ] &&
					[ -f "$CF_NGINX_SSL_DIR/$domain/$CF_CA_CERT_BASE" ]
			then
				log "INFO The $CF_TYPE certificate for domain '$domain' already exists"
				continue
			fi

			log "INFO The $CF_TYPE certificate for domain '$domain' does not exist"
		fi

		log "INFO Obtaining a $CF_TYPE certificate for domain '$domain'"

		cf_create "$domain" || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to obtain a $CF_TYPE certificate for domain '$domain' with status '$status'"
			break
		fi

		log "INFO Successfully obtained a $CF_TYPE certificate for domain '$domain'"
	done

	IFS="$ifs"

	if [ $status -ne 0 ]; then
		log "ERROR Failed to obtain $CF_TYPE certificates with status '$status'"
		return $status
	fi

	log "INFO Successfully obtained $CF_TYPE certificates"

	cf_nginx "$skip"
}

cf_schedule() {
	log "INFO Scheduling a cron job"

	if ! pgrep -x crond > /dev/null 2>&1; then
		log "INFO Cron daemon is not running, starting it"
		crond
	fi

	entries=$(crontab -l 2> /dev/null)
	if echo "$entries" | grep -F "$CF_CRON_ENTRY" > /dev/null 2>&1; then
		log "INFO The cron job is already scheduled"
		return
	fi

	printf "%s\n%s\n" "$entries" "$CF_CRON_ENTRY" | crontab -
	log "INFO Successfully scheduled a cron job"
}

cf_trigger() {
	status=0

	log "INFO Triggering scheduled operations"

	rid=$(uuid)

	_=$(healthchecks_ping start "$rid") || true
	cf_renew 0 || status=$?
	_=$(healthchecks_ping "$status" "$rid") || true

	if [ $status -ne 0 ]; then
		log "ERROR Failed to trigger scheduled operations with status '$status'"
		return $status
	fi

	log "INFO Successfully triggered scheduled operations"
}

cf_renew() {
	status=0

	force=$1
	skip=1

	log "INFO Renewing certificates"

	ifs="$IFS"
	IFS=","

	for domain in $CF_DOMAINS; do
		if [ "$force" -eq 1 ]; then
			log "INFO Forcing the renewal of the certificate for domain '$domain'"
		else
			log "INFO Checking the validity of the certificate for domain '$domain'"

			openssl_check "$domain" || status=$?
			if [ $status -eq 0 ]; then
				log "INFO The certificate for domain '$domain' is still valid"
				continue
			fi

			log "INFO The certificate for domain '$domain' is expired or about to expire"
		fi

		log "INFO Renewing the certificate for domain '$domain'"

		cf_revoke "$domain" || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to renew the certificate for domain '$domain' with status '$status'"
			break
		fi

		cf_create "$domain" || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to renew the certificate for domain '$domain' with status '$status'"
			break
		fi

		log "INFO Successfully renewed the certificate for domain '$domain'"

		skip=0
	done

	IFS="$ifs"

	if [ $status -ne 0 ]; then
		log "ERROR Failed to renew certificates with status '$status'"
		return $status
	fi

	log "INFO Successfully renewed certificates"

	cf_nginx "$skip"
}

cf_logs() {
	follow=$1
	lines=$2
	options=""

	if [ "$follow" -eq 1 ]; then
		options="$options -f"
	fi

	if [ "$lines" -gt 0 ]; then
		options="$options -n $lines"
	fi

	# shellcheck disable=SC2086
	tail $options "$CF_SELF_LOG_FILE"
}

cf_env() {
	echo "CF_ENABLED=$CF_ENABLED"
	echo "CF_CRON=$CF_CRON"
	echo "CF_DAYS=$CF_DAYS"
	echo "CF_DOMAINS=$CF_DOMAINS"
	echo "CF_TYPE=$CF_TYPE"
	echo "CF_API_TOKEN=$CF_API_TOKEN"
	echo "CF_HEALTHCHECKS_URL=$CF_HEALTHCHECKS_URL"
}

cf_create() {
	status=0

	domain=$1

	log "INFO Creating a $CF_TYPE certificate for domain '$domain'"

	# shellcheck disable=SC2043
	for _ in _; do
		log "INFO Sending a request to Cloudflare for domain '$domain'"

		res=$(cloudflare_create "$domain") || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to send request to Cloudflare for domain '$domain' with status '$status'"
			log "ERROR Cloudflare response: $res"
			break
		fi

		log "INFO Successfully sent a request to Cloudflare for domain '$domain'"

		log "INFO Parsing the response from Cloudflare for domain '$domain'"

		success=$(echo "$res" | grep -o '"success": *true')
		if [ -z "$success" ]; then
			status=1
			log "ERROR Failed to parse the response from Cloudflare for domain '$domain'"
			log "ERROR Cloudflare response: $res"
			break
		fi

		id=$(echo "$res" | grep -o '"id": *"[^"]*' | cut -d'"' -f4)
		if [ -z "$id" ]; then
			status=1
			log "ERROR Failed to parse the response from Cloudflare for domain '$domain'"
			log "ERROR Cloudflare response: $res"
			break
		fi

		cert=$(echo "$res" | grep -o '"certificate": *"[^"]*' | cut -d'"' -f4)
		if [ -z "$cert" ]; then
			status=1
			log "ERROR Failed to parse the response from Cloudflare for domain '$domain'"
			log "ERROR Cloudflare response: $res"
			break
		fi

		log "INFO Successfully parsed the response from Cloudflare for domain '$domain'"

		log "INFO Saving the $CF_TYPE certificate for domain '$domain'"

		dir="$CF_CLOUDFLARE_CONFIG_DIR/$domain"
		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		file="$CF_CLOUDFLARE_CONFIG_DIR/$domain/$CF_ID_BASE"
		echo "$id" > "$file"
		chmod 600 "$file"

		file="$CF_CLOUDFLARE_CONFIG_DIR/$domain/$CF_CERT_BASE"
		echo "$cert" > "$file"
		chmod 644 "$file"

		dir="$CF_NGINX_SSL_DIR/$domain"
		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		file="$CF_NGINX_SSL_DIR/$domain/$CF_CA_CERT_BASE"
		echo "$cert" > "$file"
		chmod 644 "$file"

		log "INFO Successfully saved the $CF_TYPE certificate for domain '$domain'"
	done

	if [ $status -ne 0 ]; then
		log "ERROR Failed to create a $CF_TYPE certificate for domain '$domain' with status '$status'"
		return $status
	fi

	log "INFO Successfully created a $CF_TYPE certificate for domain '$domain'"
}

cf_revoke() {
	status=0

	domain=$1

	log "INFO Revoking a $CF_TYPE certificate for domain '$domain'"

	# shellcheck disable=SC2043
	for _ in _; do
		log "INFO Reading the ID of the certificate for domain '$domain'"

		file="$CF_CLOUDFLARE_CONFIG_DIR/$domain/$CF_ID_BASE"
		if [ ! -f "$file" ]; then
			status=1
			log "ERROR Failed to read the ID of the certificate for domain '$domain'"
			break
		fi

		id=$(< "$file" tr -d '\n')
		if [ -z "$id" ]; then
			status=1
			log "ERROR Failed to read the ID of the certificate for domain '$domain'"
			break
		fi

		log "INFO Successfully read the ID of the certificate for domain '$domain'"

		log "INFO Sending a request to Cloudflare for domain '$domain'"

		res=$(cloudflare_revoke "$id") || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to send request to Cloudflare for domain '$domain' with status '$status'"
			log "ERROR Cloudflare response: $res"
			break
		fi

		log "INFO Successfully sent a request to Cloudflare for domain '$domain'"

		log "INFO Deleting the certificate for domain '$domain'"

		dir="$CF_NGINX_SSL_DIR/$domain"
		rm -rf "$dir"

		log "INFO Successfully deleted the certificate for domain '$domain'"
	done

	if [ $status -ne 0 ]; then
		log "ERROR Failed to revoke a $CF_TYPE certificate for domain '$domain' with status '$status'"
		return $status
	fi

	log "INFO Successfully revoked a $CF_TYPE certificate for domain '$domain'"
}

cf_nginx() {
	status=0

	skip=$1

	log "INFO Running Nginx operations"

	# shellcheck disable=SC2043
	for _ in _; do
		log "INFO Populating Nginx configuration"

		nginx_populate || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to populate Nginx configuration with status '$status'"
			break
		fi

		log "INFO Successfully populated Nginx configuration"

		if [ "$skip" -eq 1 ]; then
			log "INFO Skipping rendering, testing Nginx configuration and reloading Nginx"
			break
		fi

		log "INFO Rendering Nginx configuration"

		ng render || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to render Nginx configuration with status '$status'"
			break
		fi

		log "INFO Successfully rendered Nginx configuration"

		log "INFO Testing Nginx configuration"

		nginx_test || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to test Nginx configuration with status '$status'"
			break
		fi

		log "INFO Successfully tested Nginx configuration"

		log "INFO Reloading Nginx"

		nginx_reload || status=$?
		if [ $status -ne 0 ]; then
			log "ERROR Failed to reload Nginx with status '$status'"
			break
		fi

		log "INFO Successfully reloaded Nginx"
	done

	if [ $status -ne 0 ]; then
		log "ERROR Failed to run Nginx operations with status '$status'"
		return $status
	fi

	log "INFO Successfully ran Nginx operations"
}

openssl_check() {
	openssl x509 \
		-checkend "$((CF_THRESHOLD_DAYS * 24 * 60 * 60))" \
		-in "$CF_NGINX_SSL_DIR/$1/$CF_CA_CERT_BASE" \
		-noout
}

cloudflare_create() {
	cloudflare_base "https://api.cloudflare.com/client/v4/certificates" \
		--method POST \
		--header "Content-Type: application/json" \
		--body-data "{
			\"hostnames\": [\"$1\"],
			\"request_type\": \"$CF_TYPE\",
			\"requested_validity\": $CF_DAYS
		}"
}

cloudflare_revoke() {
	cloudflare_base "https://api.cloudflare.com/client/v4/certificates/$1" \
		--method DELETE
}

cloudflare_base() {
	wget \
		--header "Accept: application/json" \
		--header "Authorization: Bearer $CF_API_TOKEN" \
		--header "User-Agent: $USER_AGENT" \
		--output-document - \
		--timeout 10 \
		--tries 5 \
		"$@"
}

nginx_populate() {
	ifs="$IFS"
	IFS=","

	for domain in $CF_DOMAINS; do
		dir="$CF_NGINX_SNIPPETS_DIR/$domain"
		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		file="$dir/$CF_SSL_CLIENT_CERTIFICATE_BASE"
		if [ ! -f "$file" ]; then
			nginx_domain_ssl_client_certificate_conf "$domain" > "$file"
		fi
	done

	IFS="$ifs"
}

nginx_domain_ssl_client_certificate_conf() {
	echo "ssl_client_certificate $CF_NGINX_SSL_DIR/$1/$CF_CA_CERT_BASE;"
}

nginx_test() {
	nginx -t
}

nginx_reload() {
	nginx -s reload
}

healthchecks_ping() {
	if [ -n "$CF_HEALTHCHECKS_URL" ]; then
		wget \
			--header "Accept: text/plain" \
			--header "User-Agent: $CF_USER_AGENT" \
			--output-document - \
			--quiet \
			--timeout 10 \
			--tries 5 \
			"$(url "$CF_HEALTHCHECKS_URL" "$1")?rid=$2"
	fi
}

url() {
	b="$1"

	case "$b" in
	*/)
		b="${b%/}"
		;;
	esac

	echo "$b/$2"
}

uuid() {
	cat /proc/sys/kernel/random/uuid
}

main "$@"
