#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "basedata" "$@"
}

CURRMODEM=$1
COMMPORT=$2

get_base() {
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "baseinfo.gcom" "$CURRMODEM")
	O=$($ROOTER/common/processat.sh "$OX")
}

get_base

COPS="-"
COPS_MCC="-"
COPS_MNC="-"

COPSX=$(echo "$O" | awk -F[\"] '/^\+COPS: 0,0/ {print $2}')
if [ "x$COPSX" != "x" ]; then
	COPS=$COPSX
fi

COPSX=$(echo "$O" | awk -F[\"] '/^\+COPS: 0,2/ {print $2}')
if [ "x$COPSX" != "x" ]; then
	COPS_MCC=${COPSX:0:3}
	COPS_MNC=${COPSX:3:3}
	if [ "$COPS" = "-" ]; then
		COPS=$(awk -F[\;] '/'$COPS'/ {print $2}' $ROOTER/signal/mccmnc.data)
		[ "x$COPS" = "x" ] && COPS="-"
	fi
fi

if [ "$COPS" = "-" ]; then
	COPS=$(echo "$O" | awk -F[\"] '/^\+COPS: 0,0/ {print $2}')
	if [ "x$COPS" = "x" ]; then
		COPS="-"
		COPS_MCC="-"
		COPS_MNC="-"
	fi
fi
COPS_MNC=" "$COPS_MNC

DOWN=$(echo "$O" | awk -F[,] '/\+CGEQNEG:/ {printf "%s", $4}')
if [ "x$DOWN" != "x" ]; then
	UP=$(echo "$O" | awk -F[,] '/\+CGEQNEG:/ {printf "%s", $3}')
	DOWN=$DOWN" kbps Down | "
	UP=$UP" kbps Up"
else
	DOWN="-"
	UP="-"
fi

MANUF=$(echo "$O" | awk -F[:] '/Manufacturer:/ { print $2}')
if [ "x$MANUF" = "x" ]; then
	MANUF=$(uci get modem.modem$CURRMODEM.manuf)
fi

MODEL=$(echo "$O" | awk -F[,\ ] '/^\+MODEL:/ {print $2}')
if [ "x$MODEL" != "x" ]; then
	MODEL=$(echo "$MODEL" | sed -e 's/"//g')
	if [ $MODEL = 0 ]; then
		MODEL = "mf820"
	fi
else
	MODEL=$(uci get modem.modem$CURRMODEM.model)
fi
MODEM=$MANUF" "$MODEL

echo 'COPS="'"$COPS"'"' > /tmp/base$CURRMODEM.file
echo 'COPS_MCC="'"$COPS_MCC"'"' >> /tmp/base$CURRMODEM.file
echo 'COPS_MNC="'"$COPS_MNC"'"' >> /tmp/base$CURRMODEM.file
echo 'MODEM="'"$MODEM"'"' >> /tmp/base$CURRMODEM.file
echo 'DOWN="'"$DOWN"'"' >> /tmp/base$CURRMODEM.file
echo 'UP="'"$UP"'"' >> /tmp/base$CURRMODEM.file



