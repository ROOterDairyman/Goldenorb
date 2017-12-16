#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "QMI Connect" "$@"
}

CURRMODEM=$1
device=/dev/$2
auth=$3
NAPN=$4
username=$5
password=$6
pincode=$7

interface="wan"$CURRMODEM

case $auth in
	"0" )
		auth="none"
	;;
	"1" )
		auth="pap"
	;;
	"2" )
		auth="chap"
	;;
	*)
		auth="none"
	;;
esac
if [ $username = NIL ]; then
	username=
fi
if [ $password = NIL ]; then
	password=
fi

devname="$(basename "$device")"
devpath="$(readlink -f /sys/class/usbmisc/$devname/device/)"
ifname="$( ls "$devpath"/net )"

while uqmi -s -d "$device" --get-pin-status | grep '"UIM uninitialized"' > /dev/null; do
		sleep 1;
done

[ -n "$pincode" ] && {
	uqmi -s -d "$device" --verify-pin1 "$pincode" || {
		log "Unable to verify PIN"
		exit 1
	}
}

uqmi -s -d "$device" --stop-network 0xffffffff --autoconnect > /dev/null & sleep 10 ; kill -9 $!

uqmi -s -d "$device" --set-data-format 802.3
uqmi -s -d "$device" --wda-set-data-format 802.3
DATAFORM=$(uqmi -s -d "$device" --wda-get-data-format)
log "WDA-GET-DATA-FORMAT is $DATAFORM"

log "Waiting for network registration"
while uqmi -s -d "$device" --get-serving-system | grep '"searching"' > /dev/null; do
	sleep 5;
done

log "Starting network $NAPN"
cid=`uqmi -s -d "$device" --get-client-id wds`
[ $? -ne 0 ] && {
	log "Unable to obtain client ID"
	exit 1
}

ST=$(uqmi -s -d "$device" --set-client-id wds,"$cid" --start-network ${NAPN:+--apn $NAPN} ${auth:+--auth-type $auth} \
	${username:+--username $username} ${password:+--password $password} --autoconnect)
log "Connection returned : $ST"

CONN=$(uqmi -s -d "$device" --get-data-status)
log "status is $CONN"

CONNZX=$(uqmi -s -d $device --set-client-id wds,$cid --get-current-settings)
log "GET-CURRENT-SETTINGS is $CONNX"

T=$(echo $CONN | grep "disconnected")
if [ -z $T ]; then
	echo "1" > /tmp/qmigood
#	if [ $DATAFORM = "raw-ip" ]; then
		json_load "$(uqmi -s -d $device --set-client-id wds,$cid --get-current-settings)"
		json_select ipv4
		json_get_vars ip subnet gateway dns1 dns2
		
		proto_init_update "$ifname" 1
		proto_set_keep 1
		proto_add_ipv4_address "$ip" "$subnet"
		proto_add_dns_server "$dns1"
		proto_add_dns_server "$dns2"
		proto_add_ipv4_route "0.0.0.0" 0 "$gateway"
		proto_add_data
		json_add_string "cid_4" "$cid"
		json_add_string "pdh_4" "$ST"
		proto_close_data
		proto_send_update "$interface"
#	fi
else
	uqmi -s -d "$device" --stop-network 0xffffffff --autoconnect > /dev/null & sleep 10 ; kill -9 $!
fi

