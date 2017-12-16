#!/bin/sh

ROOTER=/usr/lib/rooter

CURRMODEM=$1

if [ -e /etc/config/mwan3 ]; then
	ENB=$(uci get mwan3.wan$CURRMODEM.enabled)
	if [ ! -z $ENB ]; then
		uci set mwan3.wan$CURRMODEM.enabled=0
		uci commit mwan3
	fi
fi