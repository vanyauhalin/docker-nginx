#!/bin/sh

set -ue

./le.sh self >> ./le.log 2>&1
crond
./le.sh job >> ./le.log 2>&1
exec nginx -g "daemon off;"
