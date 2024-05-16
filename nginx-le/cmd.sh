#!/bin/sh

set -ue

./le.sh self >> ./le.log 2>&1
nginx -g "daemon off;"

crond
./le.sh job >> ./le.log 2>&1
