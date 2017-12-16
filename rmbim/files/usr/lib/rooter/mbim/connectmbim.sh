#!/bin/sh


ROOTER=/usr/lib/rooter

log() {
	logger -t "MBIM Connect" "$@"
}

	. /lib/functions.sh
	. /lib/netifd/netifd-proto.sh

device=/dev/$1
CURRMODEM=$2
NAUTH=$3
NAPN=$4
NUSER=$5
NPASS=$6
PINC=$7

case $NAUTH in
	"0" )
		NAUTH=
	;;
	"1" )
		NAUTH="pap"
	;;
	"2" )
		NAUTH="chap"
	;;
esac
if [ $NUSER = NIL ]; then
	NUSER=
fi
if [ $NPASS = NIL ]; then
	NPASS=
fi

	devname="$(basename "$device")"
	devpath="$(readlink -f /sys/class/usbmisc/$devname/device/)"
	ifname="$( ls "$devpath"/net )"

tid=2

IMEI="Unknown"
IMSI="Unknown"
ICCID="Unknown"
CNUM="*"
CNUMx="*"

log "Open modem and get capabilities"
DCAPS=$(umbim -v -n -d $device caps)
retq=$?
if [ $retq -eq 0 ]; then
	CUSTOM=$(echo "$DCAPS" | awk '/customdataclass:/ {print $2}')
	IMEI=$(echo "$DCAPS" | awk '/deviceid:/ {print $2}')
	echo 'CUSTOM="'"$CUSTOM"'"' > /tmp/mbimcustom$CURRMODEM
	tid=$((tid + 1))
	if [ ! -z $PINC ]; then
		log "Sending PIN"
		umbim -n -t $tid -d $device unlock "$pincode"
		retq=$?
		if [ $retq -ne 0 ]; then
			log "Pin unlock failed"
			exit 1
		fi
	fi
	tid=$((tid + 1))
	log "Check PIN state"
	umbim -n -t $tid -d $device pinstate
	retq=$?
	if [ $retq -eq 2 ]; then
		log "PIN is required"
		exit 1
	else
		log "PIN unlocked"
	fi

	tid=$((tid + 1))
	log "Check Subscriber ready state"
	SUB=$(umbim -n -t $tid -d $device subscriber)
	retq=$?
	IMSI=$(echo "$SUB" | awk '/subscriberid:/ {print $2}')
	ICCID=$(echo "$SUB" | awk '/simiccid:/ {print $2}')
	CNUM=$(echo "$SUB" | awk '/number:/ {print $2}')

	tid=$((tid + 1))
	log "Check Network Registration"
	REG=$(umbim -v -n -t $tid -d $device registration)
	retq=$?
	if [ $retq != 0 ]; then
		if [ $retq != 4 ]; then
			log "Failed to Register"
			exit 1
		fi
	fi
	log "Registered to network"
	MCCMNC=$(echo "$REG" | awk '/provider_id:/ {print $2}')
	PROV=$(echo "$REG" | awk '/provider_name:/ {print $2}')
	MCC=${MCCMNC:0:3}
	MNC=${MCCMNC:3}
	echo 'MCC="'"$MCC"'"' > /tmp/mbimmcc$CURRMODEM
	echo 'MNC="'"$MNC"'"' >> /tmp/mbimmcc$CURRMODEM
	echo 'PROV="'"$PROV"'"' >> /tmp/mbimmcc$CURRMODEM
	tid=$((tid + 1))
	log "Try to Attach to network"
	ATTACH=$(umbim -v -n -t $tid -d $device attach)
	retq=$?
	if [ $retq != 0 ]; then
		log "Failed to attach to network"
		exit 1
	else
		log "Attached to network"
	fi
	log "Attempt to connect to network"
	COUNTER=1
	BRK=0
	while [ $COUNTER -lt 6 ]; do
		umbim -v -n -t $tid -d $device connect "$NAPN" "$NAUTH" "$NUSER" "$NPASS"
		retq=$?
		if [ $retq != 0 ]; then
			tid=$((tid + 1))
			sleep 1;
			let COUNTER=COUNTER+1
		else
			log "Connected to network"
			BRK=1
			break
		fi 
	done

	if [ $BRK -eq 0 ]; then
		log "Failed to connect to network"
		exit 1
	fi

	tid=$((tid + 1))

	log "Get IP config"
	CONFIG=$(umbim -v -n -t $tid -d $device config) || {
		log "config failed"
		return 1
	}
	tid=$((tid + 1))
	
	IP=$(echo -e "$CONFIG"|grep "ipv4address"|grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")
	DNS=$(echo -e "$CONFIG"|grep "ipv4dnsserver"|grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" |sed -n 1p)
	DNS2=$(echo -e "$CONFIG"|grep "ipv4dnsserver"|grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" |sed -n 2p)

	log "IP: $IP"
	log "DNS1: $DNS"
	log "DNS2: $DNS2"

	interface="wan$CURRMODEM"
	ifup $interface
	sleep 3
	uci_set_state network $interface tid "$tid"

	log "Connected, starting DHCP"
	proto_init_update "$ifname" 1
	proto_add_ipv4_address $IP "255.255.255.255"
	proto_add_ipv4_route "0.0.0.0" 0
	proto_send_update "$interface"

	json_init
	json_add_string name "${interface}_4"
	json_add_string ifname "@$interface"
	json_add_string proto "static"

	INTER=$(uci get modem.modem$CURRMODEM.interface)
	ifconfig $INTER $IP netmask "255.255.255.255" up
	route add default dev $IP
	echo "nameserver $DNS" >> /tmp/resolv.conf.auto
	echo "nameserver $DNS2" >> /tmp/resolv.conf.auto

	IDP=$(uci get modem.modem$CURRMODEM.idP)
	IDV=$(uci get modem.modem$CURRMODEM.idV)

	echo $IDV" : "$IDP > /tmp/msimdatax$CURRMODEM
	echo "$IMEI" >> /tmp/msimdatax$CURRMODEM
	echo "$IMSI" >> /tmp/msimdatax$CURRMODEM
	echo "$ICCID" >> /tmp/msimdatax$CURRMODEM
	echo "1" >> /tmp/msimdatax$CURRMODEM
	mv -f /tmp/msimdatax$CURRMODEM /tmp/msimdata$CURRMODEM
	echo "$CNUM" > /tmp/msimnumx$CURRMODEM
	echo "$CNUMx" >> /tmp/msimnumx$CURRMODEM
	mv -f /tmp/msimnumx$CURRMODEM /tmp/msimnum$CURRMODEM

	ATTACH=$(umbim -n -t $tid -d $device attach)
	UP=$(echo "$ATTACH" | awk '/uplinkspeed:/ {print $2}')
	DWN=$(echo "$ATTACH" | awk '/downlinkspeed:/ {print $2}')
	MODE=$(echo "$ATTACH" | awk '/highestavailabledataclass:/ {print $2}')
	echo 'UP="'"$UP"'"' > /tmp/mbimqos$CURRMODEM
	echo 'DOWN="'"$DWN"'"' >> /tmp/mbimqos$CURRMODEM
	if [ $MODE == "0001" ]; then
		CLASS="GPRS"
	fi
	if [ $MODE == "0002" ]; then
		CLASS="EDGE"
	fi
	if [ $MODE == "0004" ]; then
		CLASS="UMTS"
	fi
	if [ $MODE == "0008" ]; then
		CLASS="HSDPA"
	fi
	if [ $MODE == "0010" ]; then
		CLASS="HSUPA"
	fi
	if [ $MODE == "0020" ]; then
		CLASS="LTE"
	fi
	CUS=${MODE:0:1}
	if [ $CUS = "8" ]; then
		CLASS="CUSTOM"
	fi
	if [ -z $CLASS ]; then
		CLASS="UNKNOWN"
	fi
	echo 'MODE="'"$CLASS"'"' > /tmp/mbimmode$CURRMODEM
	tid=$((tid + 1))
	SIGNAL=$(umbim -n -t $tid -d $device signal)
	CSQ=$(echo "$SIGNAL" | awk '/rssi:/ {print $2}')
	echo 'CSQ="'"$CSQ"'"' > /tmp/mbimsig$CURRMODEM
	echo "1" > /tmp/mbimgood
else
	log "Failed to open modem"
	exit 1
fi


exit 0
