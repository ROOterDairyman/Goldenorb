#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "Lock Provider" "$@"
}

setautocops() {
	ATCMDD="AT+COPS=0"
	OX=$($ROOTER/gcom/gcom-locked "$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	CLOG=$(uci get modem.modeminfo$CURRMODEM.log)
	if [ $CLOG = "1" ]; then
		log "$OX"
	fi
	exit 0
}

CURRMODEM=$1
CPORT=/dev/ttyUSB$(uci get modem.modem$CURRMODEM.commport)

LOCK=$(uci get modem.modeminfo$CURRMODEM.lock)
if [ -z $LOCK ]; then
	setautocops
fi

MCC=$(uci get modem.modeminfo$CURRMODEM.mcc)
if [ -z $MCC ]; then
	setautocops
fi
LMCC=`expr length $MCC`
if [ $LMCC -ne 3 ]; then
	setautocops
fi
MNC=$(uci get modem.modeminfo$CURRMODEM.mnc)
if [ -z $MNC ]; then
	setautocops
fi
LMNC=`expr length $MNC`
if [ $LMNC -eq 1 ]; then
	MNC=0$MNC
fi

export MCCMNC=$MCC$MNC

OX=$($ROOTER/gcom/gcom-locked "$CPORT" "lock-prov.gcom" "$CURRMODEM")
CLOG=$(uci get modem.modeminfo$CURRMODEM.log)
if [ $CLOG = "1" ]; then
	log "$OX"
fi
ERROR="ERROR"
if `echo ${OX} | grep "${ERROR}" 1>/dev/null 2>&1`
then
	log "Error While Locking to Provider"
else
	log "Locked to Provider $MCC $MNC"
fi

