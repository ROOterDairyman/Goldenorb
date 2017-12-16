#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "Delete SMS" "$@"
}

SLOT=$1
CURRMODEM=$2
COMMPORT="/dev/ttyUSB"$(uci get modem.modem$CURRMODEM.commport)

LOCKDIR="/tmp/smslock$CURRMODEM"
PIDFILE="${LOCKDIR}/PID"

ATCMDD="AT+CMGD=$SLOT"
OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")

while [ 1 -lt 6 ]; do
	if mkdir "${LOCKDIR}" &>/dev/null; then
		echo "$$" > "${PIDFILE}"
		ATCMDD="AT+CPMS=\"SM\";+CMGD=$SLOT"
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		ATCMDD="AT+CPMS=\"SM\""
		SX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		M2=$(echo "$SX" | sed -e "s/+CPMS:/+CPMS: /")
		SX=$(echo "$M2" | sed -e "s/  / /g")
		USED=$(echo "$SX" | awk -F[,\ ] '/^\+CPMS:/ {print $2}')
		log "Reread SMS Messages on Modem $CURRMODEM"
		echo "$SX" > /tmp/smstmp$CURRMODEM
		ATCMDD="AT+CMGL=4"
		SX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		SX=$(echo "$SX" | sed -e "s/+CMGL:/+CMGL: /g")
		echo "$SX" >> /tmp/smstmp$CURRMODEM
		uci set modem.modem$CURRMODEM.smsnum=$USED
		uci commit modem
		mv /tmp/smstmp$CURRMODEM /tmp/smsresult$CURRMODEM.at
		lua /usr/lib/sms/smsread.lua $CURRMODEM
		break
	else
		OTHERPID="$(cat "${PIDFILE}")"
		if [ $? = 0 ]; then
			if ! kill -0 $OTHERPID &>/dev/null; then
				rm -rf "${LOCKDIR}"
			fi
		fi
		sleep 1
	fi
done
rm -rf "${LOCKDIR}"
