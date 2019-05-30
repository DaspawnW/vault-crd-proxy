#!/bin/sh

ulimit -n 102400

exec /usr/local/bin/envoy --config-path /etc/envoy/envoy.yaml --restart-epoch $RESTART_EPOCH --drain-time-s 300 --parent-shutdown-time-s 320
