#!/bin/sh

ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

log() {
	logger -t "Reconnect Modem" "$@"
}

CURRMODEM=$1
$ROOTER_LINK/create_proto$CURRMODEM $CURRMODEM 1
