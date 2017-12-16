#!/bin/sh

uci delete network.wan6
uci commit network

/etc/init.d/network restart