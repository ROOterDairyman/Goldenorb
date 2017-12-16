#!/bin/sh

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. ../netifd-proto.sh
	init_proto "$@"
}
#DBG=-v

ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

log() {
	logger -t "MBIM Connect" "$@"
}

proto_mbim_init_config() {
	available=1
	no_device=1
	proto_config_add_string "device:device"
	proto_config_add_string apn
	proto_config_add_string pincode
	proto_config_add_string delay
	proto_config_add_string auth
	proto_config_add_string username
	proto_config_add_string password
}

_proto_mbim_setup() {
	local interface="$1"
	local tid=2
	local ret

	if [ ! -f /tmp/bootend.file ]; then
		return 0
	fi

	CURRMODEM=${interface:3}
	uci set modem.modem$CURRMODEM.connected=0
	uci commit modem
	rm -f $ROOTER_LINK/reconnect$CURRMODEM
	killall -q -9 getsignal$CURRMODEM
	rm -f $ROOTER_LINK/getsignal$CURRMODEM
	killall -q -9 con_monitor$CURRMODEM
	rm -f $ROOTER_LINK/con_monitor$CURRMODEM
	killall -q -9 mbim_monitor$CURRMODEM
	rm -f $ROOTER_LINK/mbim_monitor$CURRMODEM

	local device apn pincode delay
	json_get_vars device apn pincode delay auth username password

	case $auth in
		"0" )
			auth=
		;;
		"1" )
			auth="pap"
		;;
		"2" )
			auth="chap"
		;;
	esac
	if [ $username = NIL ]; then
		username=
	fi
	if [ $password = NIL ]; then
		password=
	fi
	IMEI="Unknown"
	IMSI="Unknown"
	ICCID="Unknown"
	CNUM="*"
	CNUMx="*"

	[ -n "$ctl_device" ] && device=$ctl_device

	[ -n "$device" ] || {
		log "No control device specified"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}
	[ -c "$device" ] || {
		log "The specified control device does not exist"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}

	devname="$(basename "$device")"
	devpath="$(readlink -f /sys/class/usbmisc/$devname/device/)"
	ifname="$( ls "$devpath"/net )"

	[ -n "$ifname" ] || {
		log "Failed to find matching interface"
		proto_notify_error "$interface" NO_IFNAME
		proto_set_available "$interface" 0
		return 1
	}

	[ -n "$apn" ] || {
		log "No APN specified"
		proto_notify_error "$interface" NO_APN
		return 1
	}

	[ -n "$delay" ] && sleep "$delay"
	
	log "Query radio state"
	umbim $DBG -d $device -n radio| grep "off"
	STATUS=$?
	
	[ "$STATUS" -ne 0 ] || {
		sleep 1
		log "Setting FCC Auth"
		uqmi $DBG -m -d $device --fcc-auth
		sleep 1
	}

	log "Reading capabilities"
	tid=$((tid + 1))
	DCAPS=$(umbim $DBG -n -t $tid -d $device caps)
	retq=$?
	if [ $retq -ne 0 ]; then

		log "Failed to read modem caps"
		proto_notify_error "$interface" PIN_FAILED
		return 1
	fi
	CUSTOM=$(echo "$DCAPS" | awk '/customdataclass:/ {print $2}')
	IMEI=$(echo "$DCAPS" | awk '/deviceid:/ {print $2}')
	echo 'CUSTOM="'"$CUSTOM"'"' > /tmp/mbimcustom$CURRMODEM

	if [ ! -z $pincode ]; then
		log "Sending PIN"
		tid=$((tid + 1))
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
	log "Checking subscriber"
	SUB=$(umbim -n -t $tid -d $device subscriber)
	retq=$?
	if [ $retq -ne 0 ]; then
		log "Subscriber init failed"
		proto_notify_error "$interface" NO_SUBSCRIBER
		return 1
	fi
	IMSI=$(echo "$SUB" | awk '/subscriberid:/ {print $2}')
	ICCID=$(echo "$SUB" | awk '/simiccid:/ {print $2}')
	CNUM=$(echo "$SUB" | awk '/number:/ {print $2}')

	log "Register with network"
	for i in $(seq 30); do
		tid=$((tid + 1))
		REG=$(umbim $DBG -n -t $tid -d $device registration)
		retq=$?
		[ $retq -ne 2 ] && break
		sleep 2
	done
	if [ $retq != 0 ]; then
		if [ $retq != 4 ]; then
			log "Subscriber registration failed"
			proto_notify_error "$interface" NO_REGISTRATION
			return 1
		fi
	fi
	MCCMNC=$(echo "$REG" | awk '/provider_id:/ {print $2}')
	PROV=$(echo "$REG" | awk '/provider_name:/ {print $2}')
	MCC=${MCCMNC:0:3}
	MNC=${MCCMNC:3}

	tid=$((tid + 1))

	log "Attach to network"
	ATTACH=$(umbim -n -t $tid -d $device attach)
	retq=$?
	if [ $retq != 0 ]; then
		log "Failed to attach to network"
		proto_notify_error "$interface" ATTACH_FAILED
		return 1
	fi
	UP=$(echo "$ATTACH" | awk '/uplinkspeed:/ {print $2}')
	DOWN=$(echo "$ATTACH" | awk '/downlinkspeed:/ {print $2}')
	MODE=$(echo "$ATTACH" | awk '/highestavailabledataclass:/ {print $2}')
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

	log "Connect to network"
	state="connect"
	for i in $(seq 30); do
		tid=$((tid + 1))
		case $state in
		connect)
			umbim $DBG -d $device -n -t $tid connect "$apn" "$auth" "$username" "$password" >/dev/null
			retq=$?
			[ $retq -ne 3 -a $retq -ne 255 ] && state="status"
			;;
		status)
			CONNECT=$(umbim $DBG -d $device -n -t $tid status)
			retq=$?
			[ $retq -eq 0 ] && break
			[ $retq -eq 3 ] && state="connect"
			;;
		esac
		sleep 1
	done
	[ -n "$CONNECT" ] && echo "$CONNECT"
	if [ $retq -ne 0 ]; then
		log "Connection failed"
		return 1
	fi
	tid=$((tid + 1))
	
	log "Get IP config"
	CONFIG=$(umbim $DBG -d $device -n -t $tid config) || {
		log "config failed"
		return 1
	}
	
	IP=$(echo -e "$CONFIG"|grep "ipv4address"|grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")
	DNS=$(echo -e "$CONFIG"|grep "ipv4dnsserver"|grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" |sed -n 1p)
	DNS2=$(echo -e "$CONFIG"|grep "ipv4dnsserver"|grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" |sed -n 2p)
	IP6=$(echo "$CONFIG" | awk '/ipv6address:/ {print $2}' | cut -d / -f 1)
	DNS3=$(echo "$CONFIG" | awk '/ipv6dnsserver:/ {print $2}' | sed -n 1p)
	DNS4=$(echo "$CONFIG" | awk '/ipv6dnsserver:/ {print $2}' | sed -n 2p)
		
	echo "IP: $IP"
	echo "IPv6: $IP6/64"
	echo "DNS1: $DNS"
	echo "DNS2: $DNS2"
	echo "DNS3: $DNS3"
	echo "DNS4: $DNS4"
	
	log "Connected, setting IP"
	
	proto_init_update "$ifname" 1
	
	proto_add_ipv4_address $IP "255.255.255.255"
	proto_add_ipv4_route "0.0.0.0" 0
	proto_add_dns_server $DNS
	proto_add_dns_server $DNS2

	if [ -n "$IP6" ]; then
		# RFC 7278: Extend an IPv6 /64 Prefix to LAN
		proto_add_ipv6_address $IP6 128
		proto_add_ipv6_prefix $IP6/64
		proto_add_ipv6_route "::0" 0 "" "" "" $IP6/64
		proto_add_dns_server $DNS3
		proto_add_dns_server $DNS4
	fi

	proto_send_update "$interface"
	
	json_init
	json_add_string name "${interface}_4"
	json_add_string ifname "@$interface"
	json_add_string proto "static"

	tid=$((tid + 1))
	uci_set_state network $interface tid "$tid"
	SIGNAL=$(umbim $DBG -n -t $tid -d $device signal)
	CSQ=$(echo "$SIGNAL" | awk '/rssi:/ {print $2}')

	MAN=$(uci get modem.modem$CURRMODEM.manuf)
	MOD=$(uci get modem.modem$CURRMODEM.model)
	$ROOTER/log/logger "Modem #$CURRMODEM Connected ($MAN $MOD)"

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

	uci set modem.modem$CURRMODEM.custom=$CUSTOM
	uci set modem.modem$CURRMODEM.provider=$PROV
	uci set modem.modem$CURRMODEM.down=$DOWN" kbps Down | "
	uci set modem.modem$CURRMODEM.up=$UP" kbps Up"
	uci set modem.modem$CURRMODEM.mcc=$MCC
	uci set modem.modem$CURRMODEM.mnc=" "$MNC
	uci set modem.modem$CURRMODEM.sig=$CSQ
	uci set modem.modem$CURRMODEM.mode=$CLASS
	uci set modem.modem$CURRMODEM.sms=0
	uci commit modem

	COMMPORT=$(uci get modem.modem$CURRMODEM.commport)
	if [ -z $COMMPORT ]; then
		ln -s $ROOTER/mbim/mbimdata.sh $ROOTER_LINK/getsignal$CURRMODEM
	else
		$ROOTER/sms/check_sms.sh $CURRMODEM &
		$ROOTER/common/gettype.sh $CURRMODEM &
		ln -s $ROOTER/signal/modemsignal.sh $ROOTER_LINK/getsignal$CURRMODEM
	fi
	ln -s $ROOTER/connect/reconnect.sh $ROOTER_LINK/reconnect$CURRMODEM
	$ROOTER_LINK/getsignal$CURRMODEM $CURRMODEM $PROT &
	ln -s $ROOTER/connect/conmon.sh $ROOTER_LINK/con_monitor$CURRMODEM
	$ROOTER_LINK/con_monitor$CURRMODEM $CURRMODEM &
	ln -s $ROOTER/mbim/monitor.sh $ROOTER_LINK/mbim_monitor$CURRMODEM
	$ROOTER_LINK/mbim_monitor$CURRMODEM $CURRMODEM $device &

	uci set modem.modem$CURRMODEM.connected=1
	uci commit modem
	CLB=$(uci get modem.modeminfo$CURRMODEM.lb)
	if [ -e /etc/config/mwan3 ]; then
		ENB=$(uci get mwan3.wan$CURRMODEM.enabled)
		if [ ! -z $ENB ]; then
			if [ $CLB = "1" ]; then
				uci set mwan3.wan$CURRMODEM.enabled=1
			else
				uci set mwan3.wan$CURRMODEM.enabled=0
			fi
			uci commit mwan3
			/usr/sbin/mwan3 restart
		fi
	fi
	rm -f /tmp/usbwait

	return 0
}

proto_mbim_setup() {

	local ret
	_proto_mbim_setup $@
	ret=$?

	[ "$ret" = 0 ] || {
		logger "mbim bringup failed, retry in 15s"
		sleep 15
	}

	return $rt
}

proto_mbim_teardown() {
	local interface="$1"

	local device
	json_get_vars device
	local tid=$(uci_get_state network $interface tid)

	[ -n "$ctl_device" ] && device=$ctl_device

	if [ -n "$device" ]; then
		log "Stopping network"
		if [ -n "$tid" ]; then
			tid=$((tid + 1))
			umbim $DBG -t $tid -d "$device" disconnect
			uci_revert_state network $interface tid
		else
			umbim $DBG -d "$device" disconnect
		fi
	fi

	proto_init_update "*" 0
	proto_send_update "$interface"
	
}

[ -n "$INCLUDE_ONLY" ] || add_protocol mbim
