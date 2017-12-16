#!/bin/sh

MAN="$1"

killall -9 travelmate.sh

/usr/lib/hotspot/dis_hot.sh
echo "$MAN" > /tmp/hotman
/usr/lib/hotspot/travelmate.sh &

