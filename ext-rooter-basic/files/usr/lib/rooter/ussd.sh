#!/bin/sh

CURRMODEM=$(uci get modem.general.modemnum)
COMMPORT="/dev/ttyUSB"$(uci get modem.modem$CURRMODEM.commport)
ROOTER=/usr/lib/rooter

USSDSTR="$1"

while true; do
	if [ -n "$USSDSTR" ]; then
		ATCMDD="AT+CUSD=1,\"$USSDSTR\",15"
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "ussd.gcom" "$CURRMODEM" "$ATCMDD" | tr "\n" "\v")
		USSD=$(echo "$OX" | grep -o "+CUSD: .\+\",15" | tr "\v" "\n")
		USSDL=${#USSD}
		if [ $USSDL -ge 14 ]; then
			USSDL=$((USSDL - 14))
			USSD=$(printf "${USSD:10:$USSDL}")
			echo "$USSD"
		fi
	fi
	printf "(Leave blank to quit.) Enter a USSD string to send: "; read USSDSTR
	if [ -z "$USSDSTR" ]; then
		break
	fi
done
ATCMDD="AT+CUSD=2"
OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
