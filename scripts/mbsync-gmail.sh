#!/bin/bash

LOCK_FILE="/var/tmp/mbsync-lock"
PROXY_FILE="/var/tmp/proxy-mode"

if [ ! -f "$LOCK_FILE" ]
then
	touch $LOCK_FILE
	if [ -f "$PROXY_FILE" ]; then
		# execute the proxy config
		/usr/local/bin/mbsync -a -c /home/seanvk/.mbsyncrc_proxy
	else
		# execute the external proxy config
		/usr/local/bin/mbsync -a -c /home/seanvk/.mbsyncrc_open
	fi
	rm -f $LOCK_FILE
fi

exit 0
