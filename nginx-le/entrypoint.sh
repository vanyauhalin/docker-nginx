#!/bin/sh

set -ue

mkdir -p \
	"$LE_CONFIG_DIR" \
	"$LE_LOGS_DIR" \
	"$LE_WEBROOT_DIR" \
	"$LE_WORK_DIR"

./le.sh self >> ./le.log 2>&1
./le.sh job >> ./le.log 2>&1

crond
exec "$@"
