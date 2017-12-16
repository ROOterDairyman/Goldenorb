#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "Huawei Data" "$@"
}

CURRMODEM=$1
COMMPORT=$2

fix_data() {
	O=$($ROOTER/common/processat.sh "$OY")
}

process_csq() {
	CSQ=$(echo "$O" | awk -F[,\ ] '/^\+CSQ:/ {print $2}')
	[ "x$CSQ" = "x" ] && CSQ=-1
	if [ $CSQ -ge 0 -a $CSQ -le 31 ]; then
		CSQ_PER=$(($CSQ * 100/31))
		CSQ_RSSI=$((2 * CSQ - 113))
		CSQX=$CSQ_RSSI
		[ $CSQ -eq 0 ] && CSQ_RSSI="<= "$CSQ_RSSI
		[ $CSQ -eq 31 ] && CSQ_RSSI=">= "$CSQ_RSSI
		CSQ_PER=$CSQ_PER"%"
		CSQ_RSSI=$CSQ_RSSI" dBm"
	else
		CSQ="-"
		CSQ_PER="-"
		CSQ_RSSI="-"
	fi
}

process_huawei() {
	CSNR=$(echo "$O" | awk -F[,\ ] '/^\^CSNR:/ {print $2}')
	if [ "x$CSNR" != "x" ]; then
		RSCP=$CSNR
		CSNR=$(echo "$O" | awk -F[,\ ] '/^\^CSNR:/ {print $3}')
		if [ "x$CSNR" != "x" ]; then
			ECIO=$CSNR
		else
			ECIO=`expr $RSCP - $CSQX`
		fi
	else
		EC=$(echo "$O" | awk -F[,\ ] '/^\+CSQ:/ {print $4}')
		if [ "x$EC" != "x" ]; then
			ECIO=$EC
			EX=$(printf %.0f $ECIO)
			RSCP=`expr $CSQX + $EX`
		fi
	fi

	LTERSRP=$(echo "$O" | awk -F[,\ ] '/^\^LTERSRP:/ {print $2}')
	if [ "x$LTERSRP" != "x" ]; then
		RSCP=$LTERSRP" (RSRP)"
		LTERSRP=$(echo "$O" | awk -F[,\ ] '/^\^LTERSRP:/ {print $3}')
		if [ "x$LTERSRP" != "x" ]; then
			ECIO=$LTERSRP" (RSRQ)"
		else
			ECIO=`expr $RSCP - $CSQX`
		fi
	fi

	LBANDS=$(echo $O | grep -o "\^HFREQINFO:[0-9,]\+")
	LBAND=""
	printf '%s\n' "$LBANDS" | while read LBANDL; do
		BWU=$(echo $LBANDL | cut -d, -f9)
		if [ -z "$BWU" ]; then
			LBAND=""
		else
			BWU=$(($(echo $BWU) / 1000))
			BWD=$(($(echo $LBANDL | cut -d, -f6) / 1000))
			LBANDL=$(echo $LBANDL | cut -d, -f3)
			if [ -z "$LBANDL" ]; then
				LBAND=""
			else
				if [ -n "$LBAND" ]; then
					LBAND=$LBAND" aggregated with:<br />"
				fi
				LBAND=$LBAND"B"$LBANDL" (Bandwidth $BWD MHz Down | $BWU MHz Up)"
			fi
		fi
		echo "$LBAND" > /tmp/lbandvar
	done
	if [ -e /tmp/lbandvar ]; then
		read LBAND < /tmp/lbandvar
		rm /tmp/lbandvar
	fi
	if [ -z "$LBAND" ]; then
		LBAND="-"
	fi

	NETMODE="0"
	SYSCFG=$(echo "$O" | awk -F[,\"] '/^\^SYSCFGEX:/ {print $2}')
	if [ "x$SYSCFG" != "x" ]; then
		MODTYPE="3"
		case $SYSCFG in
		"00" )
			NETMODE="1"
			;;
		"01" )
			NETMODE="3"
			;;
		"03" )
			NETMODE="7"
			;;
		* )
			ACQ=${SYSCFG:0:2}
			case $ACQ in
			"01" )
				NETMODE="2"
				;;
			"02" )
				NETMODE="4"
				;;
			"03" )
				NETMODE="6"
				;;
			esac
			;;
		esac
	else
		SYSCFG=$(echo "$O" | awk -F[,\ ] '/^\^SYSCFG:/ {print $2}')
		if [ "x$SYSCFG" != "x" ]; then
			MODTYPE="4"
			case $SYSCFG in
			"7" )
				NETMODE="1"
				;;
			"13" )
				NETMODE="3"
				;;
			"14" )
				NETMODE="5"
				;;
			* )
				SYSCFG=$(echo "$O" | awk -F[,\ ] '/^\^SYSCFG:/ {print $3}')
				case $SYSCFG in
				"0" )
					NETMODE="1"
					;;
				"1" )
					NETMODE="2"
					;;
				"2" )
					NETMODE="4"
					;;
				esac
				;;
			esac
		fi
	fi


	MODE="-"
	TECH=$(echo "$O" | awk -F[,] '/^\^SYSINFOEX:/ {print $9}' | sed 's/"//g')
	if [ "x$TECH" != "x" ]; then
		MODE="$TECH"
	fi

	if [ "x$MODE" = "x-" ]; then
		TECH=$(echo "$O" | awk -F[,\ ] '/^\^SYSINFO:/ {print $7}')
		if [ "x$TECH" != "x" ]; then
			case $TECH in
				17*) MODE="HSPA+ (64QAM)";;
				18*) MODE="HSPA+ (MIMO)";;
				1*) MODE="GSM";;
				2*) MODE="GPRS";;
				3*) MODE="EDGE";;
				4*) MODE="UMTS";;
				5*) MODE="HSDPA";;
				6*) MODE="HSUPA";;
				7*) MODE="HSPA";;
				9*) MODE="HSPA+";;
				 *) MODE=$TECH;;
			esac
		fi
	fi

	CMODE=$(uci get modem.modem$CURRMODEM.cmode)
	if [ $CMODE = 0 ]; then
		NETMODE="10"
	fi
}

CSQ="-"
CSQ_PER="-"
CSQ_RSSI="-"
ECIO="-"
RSCP="-"
ECIO1=" "
RSCP1=" "
MODE="-"
MODETYPE="-"
NETMODE="-"

OY=$($ROOTER/gcom/gcom-locked "$COMMPORT" "huaweiinfo.gcom" "$CURRMODEM")

fix_data
process_csq
process_huawei

echo 'CSQ="'"$CSQ"'"' > /tmp/signal$CURRMODEM.file
echo 'CSQ_PER="'"$CSQ_PER"'"' >> /tmp/signal$CURRMODEM.file
echo 'CSQ_RSSI="'"$CSQ_RSSI"'"' >> /tmp/signal$CURRMODEM.file
echo 'ECIO="'"$ECIO"'"' >> /tmp/signal$CURRMODEM.file
echo 'RSCP="'"$RSCP"'"' >> /tmp/signal$CURRMODEM.file
echo 'ECIO1="'"$ECIO1"'"' >> /tmp/signal$CURRMODEM.file
echo 'RSCP1="'"$RSCP1"'"' >> /tmp/signal$CURRMODEM.file
echo 'MODE="'"$MODE"'"' >> /tmp/signal$CURRMODEM.file
echo 'MODTYPE="'"$MODTYPE"'"' >> /tmp/signal$CURRMODEM.file
echo 'NETMODE="'"$NETMODE"'"' >> /tmp/signal$CURRMODEM.file
echo 'LBAND="'"$LBAND"'"' >> /tmp/signal$CURRMODEM.file

CONNECT=$(uci get modem.modem$CURRMODEM.connected)
if [ $CONNECT -eq 0 ]; then
	exit 0
fi

if [ $CSQ = "-" ]; then
	log "$OY"
fi

ENB="0"
if [ -e /etc/config/failover ]; then
	ENB=$(uci get failover.enabled.enabled)
fi
if [ $ENB = "1" ]; then
	exit 0
fi

WWANX=$(uci get modem.modem$CURRMODEM.interface)
OPER=$(cat /sys/class/net/$WWANX/operstate 2>/dev/null)

if [ ! $OPER ]; then
	exit 0
fi
if echo $OPER | grep -q "unknown"; then
	exit 0
fi

if echo $OPER | grep -q "down"; then
	echo "1" > "/tmp/connstat"$CURRMODEM
fi
