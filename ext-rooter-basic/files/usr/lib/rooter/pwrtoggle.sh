#!/bin/sh

ROOTER_LINK="/tmp/links"

log() {
        logger -t "Power Toggle" "$@"
}

waitfor() {
	CNTR=0
	while [ ! -e /tmp/modgone ]; do
		sleep 1
		CNTR=`expr $CNTR + 1`
		if [ $CNTR -gt 60 ]; then
			break
		fi
	done
}

rebind() {
	PORT=$1
	log "Re-binding USB driver on $PORT to reset modem"
	echo $PORT > /sys/bus/usb/drivers/usb/unbind
	sleep 15
	echo $PORT > /sys/bus/usb/drivers/usb/bind
 	sleep 20
	CURRMODEM=$(uci get modem.general.modemnum)
	if [ -f $ROOTER_LINK/reconnect$CURRMODEM ]; then
		$ROOTER_LINK/reconnect$CURRMODEM $CURRMODEM &
	fi
}

power_toggle() {
	MODE=$1
	if [ -f "/tmp/gpiopin" ]; then
		rm -f /tmp/modgone
		source /tmp/gpiopin
		echo "$GPIOPIN" > /sys/class/gpio/export
		echo "out" > /sys/class/gpio/gpio$GPIOPIN/direction
		if [ -z $GPIOPIN2 ]; then
			echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
			waitfor
			echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
		else
			echo "$GPIOPIN2" > /sys/class/gpio/export
			echo "out" > /sys/class/gpio/gpio$GPIOPIN2/direction
			if [ $MODE = 1 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
				waitfor
				echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
			fi
			if [ $MODE = 2 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN2/value
				waitfor
				echo 1 > /sys/class/gpio/gpio$GPIOPIN2/value
			fi
			if [ $MODE = 3 ]; then
				echo 0 > /sys/class/gpio/gpio$GPIOPIN/value
				echo 0 > /sys/class/gpio/gpio$GPIOPIN2/value
				waitfor
				echo 1 > /sys/class/gpio/gpio$GPIOPIN/value
				echo 1 > /sys/class/gpio/gpio$GPIOPIN2/value
			fi
			sleep 2
		fi
		rm -f /tmp/modgone
	else
		# unbind/bind driver from USB to reset modem when power toggle is selected, but not available
		if [ $MODE = 1 ]; then
			PORT="usb1"
			rebind $PORT
		fi
		if [ $MODE = 2 ]; then
			PORT="usb2"
			rebind $PORT
		fi
		rm -f /tmp/modgone
	fi
}

power_toggle $1