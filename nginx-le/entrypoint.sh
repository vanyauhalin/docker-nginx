#!/bin/sh

set -ue

./le.sh options
./le.sh dirs
./le.sh self

(
	sleep 5
	./le.sh unself
	./le.sh test
	./le.sh job
	crond
	# ./le.sh prod
) &

exec "$@"
