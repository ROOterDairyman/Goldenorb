#!/bin/sh

ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

log() {
	logger -t "Create Hostless Connection" "$@"
}

handle_timeout(){
	local wget_pid="$1"
	local count=0
	ps | grep -v grep | grep $wget_pid
	res="$?"
	while [ "$res" = 0 -a $count -lt "$((TIMEOUT))" ]; do
		sleep 1
		count=$((count+1))
		ps | grep -v grep | grep $wget_pid
		res="$?"
	done

	if [ "$res" = 0 ]; then
		log "Killing process on timeout"
		kill "$wget_pid" 2> /dev/null
		ps | grep -v grep | grep $wget_pid
		res="$?"
		if [ "$res" = 0 ]; then
			log "Killing process on timeout"
			kill -9 $wget_pid 2> /dev/null
		fi
	fi
}

set_dns() {
	local DNS1=$(uci get modem.modeminfo$CURRMODEM.dns1)
	local DNS2=$(uci get modem.modeminfo$CURRMODEM.dns2)
	if [ -z $DNS1 ]; then
		if [ -z $DNS2 ]; then
			return
		else
			uci set network.wan$CURRMODEM.peerdns=0
			uci set network.wan$CURRMODEM.dns=$DNS2
		fi
	else
		uci set network.wan$CURRMODEM.peerdns=0
		if [ -z $DNS2 ]; then
			uci set network.wan$CURRMODEM.dns="$DNS1"
		else
			uci set network.wan$CURRMODEM.dns="$DNS2 $DNS1"
		fi
	fi
}

set_network() {
	uci delete network.wan$CURRMODEM
	uci set network.wan$CURRMODEM=interface
	uci set network.wan$CURRMODEM.proto=dhcp
	uci set network.wan$CURRMODEM.ifname=$1
	uci set network.wan$CURRMODEM.metric=$CURRMODEM"0"
	set_dns
	uci commit network
	sleep 5
}

save_variables() {
	echo 'MODSTART="'"$MODSTART"'"' > /tmp/variable.file
	echo 'WWAN="'"$WWAN"'"' >> /tmp/variable.file
	echo 'USBN="'"$USBN"'"' >> /tmp/variable.file
	echo 'ETHN="'"$ETHN"'"' >> /tmp/variable.file
	echo 'WDMN="'"$WDMN"'"' >> /tmp/variable.file
	echo 'BASEPORT="'"$BASEPORT"'"' >> /tmp/variable.file
}

CURRMODEM=$1
source /tmp/variable.file

MAN=$(uci get modem.modem$CURRMODEM.manuf)
MOD=$(uci get modem.modem$CURRMODEM.model)
$ROOTER/signal/status.sh $CURRMODEM "$MAN $MOD" "Connecting"

$ROOTER/log/logger "Attempting to Connect Modem #$CURRMODEM ($MAN $MOD)"
log "Checking Network Interface"
set_network usb$USBN
if
	ifconfig usb$USBN
then
	log "Using usb$USBN as network interface"
	uci set modem.modem$CURRMODEM.interface=usb$USBN
	USBN=`expr 1 + $USBN`
else
	set_network eth$ETHN
	if
		ifconfig eth$ETHN
	then
		log "Using eth$ETHN as network interface"
		uci set modem.modem$CURRMODEM.interface=eth$ETHN
		ETHN=`expr 1 + $ETHN`
	fi
fi
uci commit modem

BASEP=$(uci get modem.modem$CURRMODEM.baseport)
idV=$(uci get modem.modem$CURRMODEM.idV)
idP=$(uci get modem.modem$CURRMODEM.idP)
if [ $idV = 1546 -a $idP = 1146 ]; then
	CPORT=1
	lua $ROOTER/common/modemchk.lua "$idV" "$idP" "$CPORT" "$CPORT"
	source /tmp/parmpass
	CPORT=`expr $CPORT + $BASEP`
	uci set modem.modem$CURRMODEM.commport=$CPORT
	uci commit modem
	$ROOTER/sms/check_sms.sh $CURRMODEM &
	$ROOTER/common/gettype.sh $CURRMODEM &
fi

save_variables
rm -f /tmp/usbwait

ifup wan$CURRMODEM
while `ifstatus wan$CURRMODEM | grep -q '"up": false\|"pending": true'`; do
	sleep 1
done
wan_ip=$(expr "`ifstatus wan$CURRMODEM | grep '"nexthop":'`" : '.*"nexthop": "\(.*\)"')
if [ $? -ne 0 ] ; then
	wan_ip=192.168.0.1
fi
uci set modem.modem$CURRMODEM.ip=$wan_ip
uci commit modem

$ROOTER/log/logger "HostlessModem #$CURRMODEM Connected with IP $wan_ip"

VENDOR=$(uci get modem.modem$CURRMODEM.idV)
case $VENDOR in
"19d2" )
	TIMEOUT=3
	wget -O /tmp/connect.file http://$wan_ip/goform/goform_set_cmd_process?goformId=CONNECT_NETWORK &
	handle_timeout "$!"
	ln -s $ROOTER/signal/ztehostless.sh $ROOTER_LINK/getsignal$CURRMODEM
	$ROOTER_LINK/getsignal$CURRMODEM $CURRMODEM $PROT &
	;;
"12d1" )
	log "Huawei Hostless"
	ln -s $ROOTER/signal/huaweihostless.sh $ROOTER_LINK/getsignal$CURRMODEM
	$ROOTER_LINK/getsignal$CURRMODEM $CURRMODEM $PROT &
	;;
* )
	log "Other Hostless"
	ln -s $ROOTER/signal/otherhostless.sh $ROOTER_LINK/getsignal$CURRMODEM
	$ROOTER_LINK/getsignal$CURRMODEM $CURRMODEM $PROT &
	;;
esac

ln -s $ROOTER/connect/conmon.sh $ROOTER_LINK/con_monitor$CURRMODEM
$ROOTER_LINK/con_monitor$CURRMODEM $CURRMODEM &

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



