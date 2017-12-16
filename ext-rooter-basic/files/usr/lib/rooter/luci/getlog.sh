#!/bin/sh


wget -O /tmp/version.file http://www.ofmodemsandmen.com/download/version.roo
ret=$?

if [ $ret = "1" ]; then
	exit 1
else
	rm -f /tmp/change.file
	wget -O /tmp/change.file http://www.ofmodemsandmen.com/download/change.roo
	cret=$?
	if [ $cret = "1" ]; then
		rm -f /tmp/version.file
		exit 1
	else
		source /tmp/version.file
		uci set modem.Version.last="$VER"
		uci commit modem
		rm -f /tmp/version.file
	fi
fi

exit 0
