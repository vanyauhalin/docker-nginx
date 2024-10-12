#!/bin/sh

set -ue

ae -p install
ae -p obtain -g -s self
ae -p schedule

exec "$@"
