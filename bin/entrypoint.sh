#!/bin/sh

set -ue

ng render

ae -p install
ae -p obtain -g -s self
ae -p schedule

exec "$@"
