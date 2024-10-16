#!/bin/sh

set -ue

AE_VERSION="0.0.1"
AE_USER_AGENT="me.vanyauhalin.docker-nginx.ae $AE_VERSION"

: "${AE_ENABLED:=1}"
: "${AE_CRON:="0	3	*	*	6"}"
: "${AE_DAYS:=90}"
: "${AE_DOMAINS:=""}"
: "${AE_EMAIL:=""}"
: "${AE_KEY_SIZE:=2048}"
: "${AE_HEALTHCHECKS_URL:=}"

AE_CRON_ENTRY="$AE_CRON	ae -p trigger"
AE_TEST_DAYS=1
AE_THRESHOLD_DAYS=30
AE_SERVER="letsencrypt"
AE_TEST_SERVER="letsencrypt_test"

AE_ACME_CONFIG_DIR="/etc/acme"
AE_ACME_HOME_DIR="$HOME/.acme.sh"
AE_NGINX_CONFIG_DIR="/etc/nginx"
AE_NGINX_SNIPPETS_DIR="$AE_NGINX_CONFIG_DIR/snippets"
AE_NGINX_SSL_DIR="$AE_NGINX_CONFIG_DIR/ssl"
AE_LOGS_DIR="/var/log"
AE_WEBROOT_DIR="/var/www"
AE_BIN_DIR="/usr/local/bin"

AE_CERT_BASE="cert.pem"
AE_CHAIN_BASE="chain.pem"
AE_DHPARAM_BASE="dhparam.pem"
AE_FULLCHAIN_BASE="fullchain.pem"
AE_PRIVKEY_BASE="privkey.pem"

AE_CERTIFICATE_BASE="certificate.conf"
AE_PROXY_CERTIFICATE_BASE="proxy-certificate.conf"
AE_CHALLENGE_BASE="challenge.conf"
AE_INTERMEDIATE_BASE="intermediate.conf"
AE_PROXY_INTERMEDIATE_BASE="proxy-intermediate.conf"
AE_REDIRECT_BASE="redirect.conf"

AE_SELF_LOGS_DIR="$AE_LOGS_DIR/ae"
AE_SELF_OUTPUT_FILE="$AE_SELF_LOGS_DIR/output.log"

ae_help() {
	echo "Usage: ae [options] <subcommand>"
	echo "       ae obtain [options] <type>"
	echo "       ae renew [options]"
	echo "       ae logs [options]"
	echo "       ae acme <arguments>"
	echo
	echo "Options:"
	echo "  -p            Pipes the output to the output file"
	echo "                (available for 'install', 'obtain', 'schedule', 'trigger' and 'renew' subcommands)"
	echo
	echo "Subcommands:"
	echo "  help          Shows this help message"
	echo "  install       Installs the client"
	echo "  obtain        Obtains certificates"
	echo "  schedule      Schedules certificate renewal"
	echo "  trigger       Triggers scheduled operations"
	echo "  renew         Renews certificates"
	echo "  logs          Shows the log file"
	echo "  env           Shows the environment variables"
	echo "  acme          Runs the acme client"
	echo
	echo "Obtain options:"
	echo "  -g            Obtains certificates only for non-existing domains"
	echo "  -s            Skips Nginx reload"
	echo
	echo "Obtain types:"
	echo "  self          Obtains self-signed certificates"
	echo "  test          Obtains test certificates"
	echo "  prod          Obtains production certificates"
	echo
	echo "Renew options:"
	echo "  -f            Forces renewal of certificates"
	echo
	echo "Logs options:"
	echo "  -f            Follows the log file"
	echo "  -n <lines>    Shows the last <lines> lines of the log file"
	echo
	echo "Environment variables:"
	echo "  AE_ENABLED             Whether ae is enabled"
	echo "  AE_CRON                Cron schedule for certificate renewal"
	echo "  AE_DAYS                Validity period for certificates when obtaining new ones"
	echo "  AE_DOMAINS             Comma-separated list of domains to obtain certificates for"
	echo "  AE_EMAIL               Email address to use when obtaining certificates"
	echo "  AE_KEY_SIZE            Size of the RSA key to be generated"
	echo "  AE_HEALTHCHECKS_URL    URL to Healthchecks check"
}

main() {
	if [ "$AE_ENABLED" -ne 1 ]; then
		return
	fi

	cmd=""
	pipe=0

	type=""
	guard=0
	skip=0

	force=0

	follow=0
	lines=0

	args=""

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

		if [ "$1" = "install" ] && [ "$cmd" = "" ]; then
			cmd="install"
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

		if [ "$1" = "self" ] && [ "$cmd" = "obtain" ]; then
			type="self"
			shift
			continue
		fi

		if [ "$1" = "test" ] && [ "$cmd" = "obtain" ]; then
			type="test"
			shift
			continue
		fi

		if [ "$1" = "prod" ] && [ "$cmd" = "obtain" ]; then
			type="prod"
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

		if [ "$1" = "acme" ] && [ "$cmd" = "" ]; then
			cmd="acme"
			args=$(arguments "acme" "$@")
			break
		fi

		break
	done

	if [ "$pipe" -eq 1 ]; then
		if [ ! -d "$AE_SELF_LOGS_DIR" ]; then
			mkdir -p "$AE_SELF_LOGS_DIR"
		fi
		if [ ! -f "$AE_SELF_OUTPUT_FILE" ]; then
			touch "$AE_SELF_OUTPUT_FILE"
		fi
	fi

	case "$cmd" in
	"")
		ae_help
		return 1
		;;
	"help")
		ae_help
		;;
	"install")
		if [ "$pipe" -eq 1 ]; then
			ae_install >> "$AE_SELF_OUTPUT_FILE" 2>&1
		else
			ae_install
		fi
		;;
	"obtain")
		if [ "$pipe" -eq 1 ]; then
			ae_obtain "$guard" "$skip" "$type" >> "$AE_SELF_OUTPUT_FILE" 2>&1
		else
			ae_obtain "$guard" "$skip" "$type"
		fi
		;;
	"schedule")
		if [ "$pipe" -eq 1 ]; then
			ae_schedule >> "$AE_SELF_OUTPUT_FILE" 2>&1
		else
			ae_schedule
		fi
		;;
	"trigger")
		if [ "$pipe" -eq 1 ]; then
			ae_trigger >> "$AE_SELF_OUTPUT_FILE" 2>&1
		else
			ae_trigger
		fi
		;;
	"renew")
		if [ "$pipe" -eq 1 ]; then
			ae_renew "$force" >> "$AE_SELF_OUTPUT_FILE" 2>&1
		else
			ae_renew "$force"
		fi
		;;
	"logs")
		ae_logs "$follow" "$lines"
		;;
	"env")
		ae_env
		;;
	"acme")
		# shellcheck disable=SC2086
		acme_base $args
		;;
	esac
}

ae_install() {
	status=0

	log "INFO Installing the client"

	dir=$(pwd)
	cd "$AE_BIN_DIR"
	cp acme acme.sh

	acme_install || status=$?
	if [ $status -ne 0 ]; then
		log "ERROR Failed to install the client with status '$status'"
		return $status
	fi

	rm acme acme.sh
	ln -s "$AE_ACME_HOME_DIR/acme.sh" "$AE_BIN_DIR/acme"
	cd "$dir"

	log "INFO Successfully installed the client"
}

ae_obtain() {
	status=0

	guard=$1
	skip=$2
	type=$3

	case "$type" in
	"self")
		title="self-signed"
		;;
	"test")
		title="test"
		;;
	"prod")
		title="production"
		;;
	esac

	log "INFO Obtaining $title certificates"

	ifs="$IFS"
	IFS=","

	for domain in $AE_DOMAINS; do
		if [ "$guard" -eq 1 ] && [ -d "$AE_NGINX_SSL_DIR/$domain" ]; then
			continue
		fi

		case "$type" in
		"self")
			openssl_self "$domain" || status=$?
			;;
		"test")
			acme_test "$domain" || status=$?
			;;
		"prod")
			acme_prod "$domain" || status=$?
			;;
		esac

		if [ $status -ne 0 ]; then
			break
		fi
	done

	IFS="$ifs"

	if [ $status -ne 0 ]; then
		log "ERROR Failed to obtain certificates with status '$status'"
		return $status
	fi

	log "INFO Successfully obtained $title certificates"

	ae_nginx "$skip"
}

ae_schedule() {
	log "INFO Scheduling cron job"

	if ! pgrep -x crond > /dev/null 2>&1; then
		log "INFO Cron daemon is not running, starting it"
		crond
	fi

	entries=$(crontab -l 2> /dev/null)
	if echo "$entries" | grep -F "$AE_CRON_ENTRY" > /dev/null 2>&1; then
		log "INFO Cron job is already scheduled"
		return
	fi

	printf "%s\n%s\n" "$entries" "$AE_CRON_ENTRY" | crontab -
	log "INFO Successfully scheduled cron job"
}

ae_trigger() {
	status=0

	log "INFO Triggering scheduled operations"

	rid=$(uuid)

	_=$(healthchecks_ping start "$rid") || true
	ae_renew 0 || status=$?
	_=$(healthchecks_ping "$status" "$rid") || true

	if [ $status -ne 0 ]; then
		log "ERROR Failed to trigger scheduled operations with status '$status'"
		return $status
	fi

	log "INFO Successfully triggered scheduled operations"
}

ae_renew() {
	status=0

	force=$1
	skip=1

	log "INFO Renewing certificates"

	ifs="$IFS"
	IFS=","

	for domain in $AE_DOMAINS; do
		if [ "$force" -eq 0 ]; then
			openssl_check "$domain" || status=$?
			if [ $status -eq 0 ]; then
				continue
			fi
		fi

		acme_renew "$domain" || status=$?
		if [ $status -ne 0 ]; then
			break
		fi

		skip=0
	done

	IFS="$ifs"

	if [ $status -ne 0 ]; then
		log "ERROR Failed to renew certificates with status '$status'"
		return $status
	fi

	log "INFO Successfully renewed certificates"

	ae_nginx "$skip"
}

ae_logs() {
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
	tail $options "$AE_SELF_OUTPUT_FILE"
}

ae_env() {
	echo "AE_ENABLED=$AE_ENABLED"
	echo "AE_CRON=$AE_CRON"
	echo "AE_DAYS=$AE_DAYS"
	echo "AE_DOMAINS=$AE_DOMAINS"
	echo "AE_EMAIL=$AE_EMAIL"
	echo "AE_KEY_SIZE=$AE_KEY_SIZE"
	echo "AE_HEALTHCHECKS_URL=$AE_HEALTHCHECKS_URL"
}

ae_nginx() {
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

		if [ "$skip" -eq 0 ]; then
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
		fi
	done

	if [ $status -ne 0 ]; then
		log "ERROR Failed to run Nginx operations with status '$status'"
		return $status
	fi

	log "INFO Successfully ran Nginx operations"
}

openssl_self() {
	dir="$AE_NGINX_SSL_DIR/$1"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi

	openssl req \
		-days "$AE_TEST_DAYS" \
		-keyout "$dir/$AE_PRIVKEY_BASE" \
		-newkey "rsa:$AE_KEY_SIZE" \
		-noenc \
		-out "$dir/$AE_FULLCHAIN_BASE" \
		-quiet \
		-subj "/CN=localhost" \
		-x509

	cp "$dir/$AE_FULLCHAIN_BASE" "$dir/$AE_CHAIN_BASE"
}

openssl_dhparam() {
	openssl dhparam \
		-quiet \
		"$AE_KEY_SIZE"
}

openssl_check() {
	openssl x509 \
		-checkend "$((AE_THRESHOLD_DAYS * 24 * 60 * 60))" \
		-in "$AE_NGINX_SSL_DIR/$1/$AE_FULLCHAIN_BASE" \
		-noout
}

acme_install() {
	acme_base --install \
		--email "$AE_EMAIL" \
		--no-cron \
		--useragent "$AE_USER_AGENT"
}

acme_test() {
	dir="$AE_WEBROOT_DIR/$1"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi

	acme_base --issue \
		--days "$AE_TEST_DAYS" \
		--domain "$1" \
		--force \
		--server "$AE_TEST_SERVER" \
		--test \
		--webroot "$dir"
}

acme_prod() {
	dir="$AE_WEBROOT_DIR/$1"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi

	acme_base --issue \
		--days "$AE_DAYS" \
		--domain "$1" \
		--force \
		--server "$AE_SERVER" \
		--webroot "$dir"

	dir="$AE_NGINX_SSL_DIR/$1"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi

	acme_base --install-cert \
		--ca-file "$dir/$AE_CHAIN_BASE" \
		--cert-file "$dir/$AE_CERT_BASE" \
		--domain "$1" \
		--fullchain-file "$dir/$AE_FULLCHAIN_BASE" \
		--key-file "$dir/$AE_PRIVKEY_BASE"
}

acme_renew() {
	acme_base --renew \
		--domain "$1" \
		--force
}

acme_base() {
	acme \
		--config-home "$AE_ACME_CONFIG_DIR" \
		--home "$AE_ACME_HOME_DIR" \
		"$@"
}

nginx_populate() {
	ifs="$IFS"
	IFS=","

	for domain in $AE_DOMAINS; do
		dir="$AE_NGINX_SNIPPETS_DIR/$domain"
		if [ ! -d "$dir" ]; then
			mkdir -p "$dir"
		fi

		file="$dir/$AE_CERTIFICATE_BASE"
		if [ ! -f "$file" ]; then
			nginx_certificate_conf "$domain" > "$file"
		fi

		file="$dir/$AE_PROXY_CERTIFICATE_BASE"
		if [ ! -f "$file" ]; then
			nginx_proxy_certificate_conf "$domain" > "$file"
		fi
	done

	IFS="$ifs"

	dir="$AE_NGINX_SNIPPETS_DIR"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi

	file="$dir/$AE_CHALLENGE_BASE"
	if [ ! -f "$file" ]; then
		nginx_challenge_conf > "$file"
	fi

	file="$dir/$AE_INTERMEDIATE_BASE"
	if [ ! -f "$file" ]; then
		nginx_intermediate_conf > "$file"
	fi

	file="$dir/$AE_PROXY_INTERMEDIATE_BASE"
	if [ ! -f "$file" ]; then
		nginx_proxy_intermediate_conf > "$file"
	fi

	file="$dir/$AE_REDIRECT_BASE"
	if [ ! -f "$file" ]; then
		nginx_redirect_conf > "$file"
	fi

	dir="$AE_NGINX_SSL_DIR"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi

	file="$dir/$AE_DHPARAM_BASE"
	if [ ! -f "$file" ]; then
		openssl_dhparam > "$file"
	fi
}

nginx_certificate_conf() {
	echo "ssl_certificate $AE_NGINX_SSL_DIR/$1/$AE_FULLCHAIN_BASE;"
	echo "ssl_certificate_key $AE_NGINX_SSL_DIR/$1/$AE_PRIVKEY_BASE;"
	echo "ssl_trusted_certificate $AE_NGINX_SSL_DIR/$1/$AE_CHAIN_BASE;"
}

nginx_proxy_certificate_conf() {
	echo "proxy_ssl_certificate $AE_NGINX_SSL_DIR/$1/$AE_FULLCHAIN_BASE;"
	echo "proxy_ssl_certificate_key $AE_NGINX_SSL_DIR/$1/$AE_PRIVKEY_BASE;"
	echo "proxy_ssl_trusted_certificate $AE_NGINX_SSL_DIR/$1/$AE_CHAIN_BASE;"
}

nginx_challenge_conf() {
	echo "location /.well-known/acme-challenge {"
	echo "	root $AE_WEBROOT_DIR/\$server_name;"
	echo "}"
}

nginx_intermediate_conf() {
	echo "ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;"
	echo "ssl_dhparam $AE_NGINX_SSL_DIR/$AE_DHPARAM_BASE;"
	echo "ssl_prefer_server_ciphers off;"
	echo "ssl_protocols TLSv1.2 TLSv1.3;"
	echo "ssl_session_cache shared:MozSSL:10m;"
	echo "ssl_session_timeout 1d;"
	echo "ssl_stapling on;"
	echo "ssl_stapling_verify on;"
}

nginx_proxy_intermediate_conf() {
	echo "proxy_ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;"
	echo "proxy_ssl_protocols TLSv1.2 TLSv1.3;"
}

nginx_redirect_conf() {
	echo "location / {"
	echo "	return 301 https://\$server_name\$request_uri;"
	echo "}"
}

nginx_test() {
	nginx -t
}

nginx_reload() {
	nginx -s reload
}

healthchecks_ping() {
	if [ -n "$AE_HEALTHCHECKS_URL" ]; then
		wget \
			--header "Accept: text/plain" \
			--header "User-Agent: $AE_USER_AGENT" \
			--output-document - \
			--quiet \
			--timeout 10 \
			--tries 5 \
			"$(url "$AE_HEALTHCHECKS_URL" "$1")?rid=$2"
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

arguments() {
	args=""
	after=0

	shift

	for arg in "$@"; do
		if [ "$arg" = "$1" ]; then
			after=1
			continue
		fi

		if [ "$after" -eq 1 ]; then
			args="$args $arg"
		fi
	done

	echo "$args" | xargs
}

log() {
	s="$1"

	case "$s" in
	INFO*)
		p=$(echo "$s" | cut -d" " -f1)
		r=$(echo "$s" | cut -d" " -f2-)
		s="$p  $r"
		;;
	esac

	printf "%b" "$(date +'%Y-%m-%d %H:%M:%S') $s\n"
}

main "$@"
