#!/bin/bash

warp-svc >/var/log/warp/log &
(
	while ! warp-cli --accept-tos registration new; do
		sleep 1
		>&2 echo "Awaiting warp-svc become online..."
	done
	warp-cli --accept-tos mode proxy
	warp-cli --accept-tos proxy port 40000
	if [ -n "$LICENSE_KEY" ]; then
		warp-cli --accept-tos registration license $LICENSE_KEY
	fi
	warp-cli -l --accept-tos connect
) &
/usr/bin/tinyproxy -d -c tinyproxy.conf
