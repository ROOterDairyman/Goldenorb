#!/bin/sh 

log() {
	logger -t "band change" "$@"
}

BAND=$1

if [ $BAND = "1" ]; then
	WW=$(uci get travelmate.global.radio24)
else
	WW=$(uci get travelmate.global.radio5)
fi

uci set wireless.wwan.device=$WW
uci set wireless.wwan.ssid="Changing Wifi Radio"
uci set wireless.wwan.encryption="none"
uci set wireless.wwan.disabled="1"
uci commit wireless
wifi
result=`ps | grep -i "travelmate.sh" | grep -v "grep" | wc -l`
if [ $result -ge 1 ]
then
	logger -t TRAVELMATE-DEBUG "Travelmate already running"
else
	/usr/lib/hotspot/travelmate.sh &
fi