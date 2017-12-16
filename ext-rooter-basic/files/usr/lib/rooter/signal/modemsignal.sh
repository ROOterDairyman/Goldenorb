#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "modem signal" "$@"
}

CURRMODEM=$1
PROTO=$2
CONN="Modem #"$CURRMODEM
STARTIME=$(date +%s)
STARTIMEX=$(date +%s)
SMSTIME=0
COMMPORT="/dev/ttyUSB"$(uci get modem.modem$CURRMODEM.commport)
NUMB=0
MONSTAT="Unknown"
rm -f /tmp/monstat$CURRMODEM

make_connect() {
	echo "Changing Port" > /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "$MODEM" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo " " >> /tmp/statusx$CURRMODEM.file
	echo " " >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "$CONN" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	echo "-" >> /tmp/statusx$CURRMODEM.file
	mv -f /tmp/statusx$CURRMODEM.file /tmp/status$CURRMODEM.file
}

make_signal() {
	echo "$COMMPORT" > /tmp/statusx$CURRMODEM.file
	echo "$CSQ" >> /tmp/statusx$CURRMODEM.file
	echo "$CSQ_PER" >> /tmp/statusx$CURRMODEM.file
	echo "$CSQ_RSSI" >> /tmp/statusx$CURRMODEM.file
	echo "$MODEM" >> /tmp/statusx$CURRMODEM.file
	echo "$COPS" >> /tmp/statusx$CURRMODEM.file
	echo "$MODE" >> /tmp/statusx$CURRMODEM.file
	echo "$LAC" >> /tmp/statusx$CURRMODEM.file
	echo "$LAC_NUM" >> /tmp/statusx$CURRMODEM.file
	echo "$CID" >> /tmp/statusx$CURRMODEM.file
	echo "$CID_NUM" >> /tmp/statusx$CURRMODEM.file
	echo "$COPS_MCC" >> /tmp/statusx$CURRMODEM.file
	echo "$COPS_MNC" >> /tmp/statusx$CURRMODEM.file
	echo "$RNC" >> /tmp/statusx$CURRMODEM.file
	echo "$RNC_NUM" >> /tmp/statusx$CURRMODEM.file
	echo "$DOWN" >> /tmp/statusx$CURRMODEM.file
	echo "$UP" >> /tmp/statusx$CURRMODEM.file
	echo "$ECIO" >> /tmp/statusx$CURRMODEM.file
	echo "$RSCP" >> /tmp/statusx$CURRMODEM.file
	echo "$ECIO1" >> /tmp/statusx$CURRMODEM.file
	echo "$RSCP1" >> /tmp/statusx$CURRMODEM.file
	echo "$MONSTAT" >> /tmp/statusx$CURRMODEM.file
	echo "$CELL" >> /tmp/statusx$CURRMODEM.file
	echo "$MODTYPE" >> /tmp/statusx$CURRMODEM.file
	echo "$CONN" >> /tmp/statusx$CURRMODEM.file
	echo "$CHANNEL" >> /tmp/statusx$CURRMODEM.file
	echo "$CNUM" >> /tmp/statusx$CURRMODEM.file
	echo "$CNAM" >> /tmp/statusx$CURRMODEM.file
	echo "$LBAND" >> /tmp/statusx$CURRMODEM.file
	mv -f /tmp/statusx$CURRMODEM.file /tmp/status$CURRMODEM.file
}

get_basic() {
	$ROOTER/signal/basedata.sh $CURRMODEM $COMMPORT
	source /tmp/base$CURRMODEM.file
	rm -f /tmp/base$CURRMODEM.file
	$ROOTER/signal/celldata.sh $CURRMODEM $COMMPORT
	source /tmp/cell$CURRMODEM.file
	rm -f /tmp/cell$CURRMODEM.file
	lua $ROOTER/signal/celltype.lua "$MODEM" $CURRMODEM
	source /tmp/celltype$CURRMODEM
	rm -f /tmp/celltype$CURRMODEM
}

get_basic
while [ 1 = 1 ]; do
	if [ -e /tmp/port$CURRMODEM.file ]; then
		source /tmp/port$CURRMODEM.file
		rm -f /tmp/port$CURRMODEM.file
		COMMPORT="/dev/ttyUSB"$PORT
		uci set modem.modem$CURRMODEM.commport=$PORT
		make_connect
		get_basic
		STARTIME=$(date +%s)
	else
		CURRTIME=$(date +%s)
		let ELAPSE=CURRTIME-STARTIME
		if [ $ELAPSE -ge 60 ]; then
			STARTIME=$CURRTIME
			$ROOTER/signal/celldata.sh $CURRMODEM $COMMPORT
			source /tmp/cell$CURRMODEM.file
			rm -f /tmp/cell$CURRMODEM.file
		fi
		if [ -e /tmp/port$CURRMODEM.file ]; then
			source /tmp/port$CURRMODEM.file
			rm -f /tmp/port$CURRMODEM.file
			COMMPORT="/dev/ttyUSB"$PORT
			uci set modem.modem$CURRMODEM.commport=$PORT
			make_connect
			get_basic
			STARTIME=$(date +%s)
		else
			VENDOR=$(uci get modem.modem$CURRMODEM.idV)
			case $VENDOR in
			"1199"|"0f3d"|"413c" )
				$ROOTER/common/sierradata.sh $CURRMODEM $COMMPORT
				;;
			"19d2" )
				$ROOTER/common/ztedata.sh $CURRMODEM $COMMPORT
				;;
			"12d1" )
				$ROOTER/common/huaweidata.sh $CURRMODEM $COMMPORT
				;;
			* )
				$ROOTER/common/otherdata.sh $CURRMODEM $COMMPORT
				;;
			esac
			CHANNEL="-"
			source /tmp/signal$CURRMODEM.file
			rm -f /tmp/signal$CURRMODEM.file
			if [ -e /tmp/phonenumber$CURRMODEM ]; then
				source /tmp/phonenumber$CURRMODEM
				rm -f /tmp/phonenumber$CURRMODEM
			fi
			make_signal
			uci set modem.modem$CURRMODEM.cmode="1"
			uci commit modem
			if [ -e /tmp/monstat$CURRMODEM ]; then
				source /tmp/monstat$CURRMODEM
			fi
			if [ -z "$MONSTAT" ]; then
				MONSTAT="Unknown"
			fi
		fi
	fi
	if [ -e /etc/netspeed ]; then
		NETSPEED=60
	else
		NETSPEED=10
	fi
	CURRTIME=$(date +%s)
	let ELAPSE=CURRTIME-STARTIMEX
	while [ $ELAPSE -lt $NETSPEED ]; do
		sleep 2
		CURRTIME=$(date +%s)
		let ELAPSE=CURRTIME-STARTIMEX
	done
	STARTIMEX=$CURRTIME
done

