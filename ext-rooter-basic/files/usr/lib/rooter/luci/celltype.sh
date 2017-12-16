#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "Cell type" "$@"
}

CURRMODEM=$1
COMMPORT="/dev/ttyUSB"$(uci get modem.modem$CURRMODEM.commport)

VENDOR=$(uci get modem.modem$CURRMODEM.idV)

case $VENDOR in
	"1199"|"0f3d" )
		ATCMDD="AT!SELRAT?"
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		OX=$($ROOTER/common/processat.sh "$OX")
		SELRAT=$(echo "$OX" | awk -F[,\ ] '/^\!SELRAT:/ {print $2}')
		if [ "x$SELRAT" != "x" ]; then
			NETMODE="-"
			case $SELRAT in
			"00" )
				NETMODE="1"
				;;
			"01" )
				NETMODE="5"
				;;
			"03" )
				NETMODE="4"
				;;
			"02" )
				NETMODE="3"
				;;
			"04" )
				NETMODE="2"
				;;
			"05" )
				NETMODE="6"
				;;
			"06" )
				NETMODE="7"
				;;
			esac
		fi
		uci set modem.modem$CURRMODEM.modemtype="2"
		uci set modem.modem$CURRMODEM.netmode=$NETMODE
		uci commit modem
		;;
	"19d2" )
		ATCMDD="AT+ZSNT?"
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		OX=$($ROOTER/common/processat.sh "$OX")
		ZSNT=$(echo "$OX" | awk -F[,\ ] '/^\+ZSNT:/ {print $2}')
		if [ "x$ZSNT" != "x" ]; then
			NETMODE="-"
			if [ $ZSNT = "0" ]; then
				ZSNTX=$(echo "$OX" | awk -F[,\ ] '/^\+ZSNT:/ {print $4}')
				case $ZSNTX in
				"0" )
					NETMODE="1"
					;;
				"1" )
					NETMODE="2"
					;;
				"2" )
					NETMODE="4"
					;;
				"6" )
					NETMODE="6"
					;;
				esac
			else
				case $ZSNT in
				"1" )
					NETMODE="3"
					;;
				"2" )
					NETMODE="5"
					;;
				"6" )
					NETMODE="7"
					;;
				esac
			fi
		fi
		uci set modem.modem$CURRMODEM.modemtype="1"
		uci set modem.modem$CURRMODEM.netmode=$NETMODE
		uci commit modem
		;;
	"12d1" )
		ATCMDD="AT^SYSCFGEX?"
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		OX=$($ROOTER/common/processat.sh "$OX")
		SYSCFG=$(echo "$OX" | awk -F[,\"] '/^\^SYSCFGEX:/ {print $2}')
		if [ "x$SYSCFG" != "x" ]; then
			NETMODE="-"
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
			uci set modem.modem$CURRMODEM.modemtype="3"
		else
			ATCMDD="AT^SYSCFG?"
			OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
			OX=$($ROOTER/common/processat.sh "$OX")
			SYSCFG=$(echo "$OX" | awk -F[,\ ] '/^\^SYSCFG:/ {print $2}')
			if [ "x$SYSCFG" != "x" ]; then
				NETMODE="-"
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
					SYSCFG=$(echo "$OX" | awk -F[,\ ] '/^\^SYSCFG:/ {print $3}')
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
				uci set modem.modem$CURRMODEM.modemtype="4"
			fi
		fi
		uci set modem.modem$CURRMODEM.netmode=$NETMODE
		uci commit modem
		;;
	"1546" )
                ATCMDD="AT+URAT?"
                OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
		URAT=$(echo $OX" " | grep -o "+URAT: .\+ OK " | tr " " ",")
		URAT1=$(echo $URAT | cut -d, -f2)
		URAT2=$(echo $URAT | cut -d, -f3)
		if [ -n "$URAT1" ]; then
			MODTYPE="5"
			NETMODE="-"
			case $URAT1 in
			"0" )
				NETMODE="3"
				;;
			"2" )
				NETMODE="5"
				;;
			"3" )
				NETMODE="7"
				;;
			* )
				case $URAT2 in
				"0" )
					NETMODE="2"
					;;
				"2" )
					NETMODE="4"
					;;
				"3" )
					NETMODE="1"
					;;
				esac
				;;
			esac
			uci set modem.modem$CURRMODEM.modemtype="5"
		fi
                uci set modem.modem$CURRMODEM.netmode=$NETMODE
                uci commit modem
		;;
	* )
		NETMODE="-"
		uci set modem.modem$CURRMODEM.netmode=$NETMODE
		uci commit modem
		;;
esac
