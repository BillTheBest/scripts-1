#!/bin/bash

LOCK_FILE="/var/tmp/offlineimap-lock"
PROXY_FILE="/var/tmp/proxy-mode"
TSOCKS_CONF_FILE=$HOME/.tsocks.conf
export TSOCKS_CONF_FILE

if [ ! -f "$LOCK_FILE" ]
then
	touch $LOCK_FILE
	if [ -f "$PROXY_FILE" ]; then
		# execute the proxy config
		/usr/bin/tsocks /usr/bin/offlineimap -o -c $HOME/.offlineimaprc
	else
		# execute the external proxy config
		/usr/bin/offlineimap -o -c $HOME/.offlineimaprc
	fi
	rm -f $LOCK_FILE
fi

exit 0
