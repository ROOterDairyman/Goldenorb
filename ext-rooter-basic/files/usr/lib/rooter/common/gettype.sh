#!/bin/sh

ROOTER=/usr/lib/rooter

CURRMODEM=$1
CPORT=$(uci get modem.modem$CURRMODEM.commport)

sleep 10

OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "gettype.gcom" "$CURRMODEM")
OX=$($ROOTER/common/processat.sh "$OX")

MANUF=$(echo "$OX" | awk -F[:] '/Manufacturer:/ { print $2}')

if [ -z "$MANUF" ]; then
        ATCMDD="AT+CGMI"
        MANUF=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
        MANUF=$(echo -e "$MANUF" | { read _V ; read _V ; echo $_V ; })
fi

if [ "x$MANUF" = "x" ]; then
	MANUF=$(uci get modem.modem$CURRMODEM.manuf)
fi

MODEL=$(echo "$OX" | awk -F[,\ ] '/^\+MODEL:/ {print $2}')

if [ -z "$MODEL" ]; then
        ATCMDD="AT+CGMM"
        MODEL=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
        MODEL=$(echo -e "$MODEL" | { read _V ; read _V ; echo $_V ; })
fi

if [ "x$MODEL" != "x" ]; then
	MODEL=$(echo "$MODEL" | sed -e 's/"//g')
	if [ $MODEL = 0 ]; then
		MODEL = "mf820"
	fi
else
	MODEL=$(uci get modem.modem$CURRMODEM.model)
fi

uci set modem.modem$CURRMODEM.manuf=$MANUF
uci set modem.modem$CURRMODEM.model=$MODEL
uci commit modem

$ROOTER/signal/status.sh $CURRMODEM "$MANUF $MODEL" "Connecting"

IMEI=$(echo "$OX" | awk -F[,\ ] '/^\IMEI:/ {print $2}')

if [ -z "$IMEI" ]; then
	ATCMDD="AT+CGSN"
	IMEI=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	IMEI=$(echo $IMEI | grep -o "[0-9]\{15\}")
fi

if [ -z "$IMEI" ]; then
	ATCMDD="ATI5"
	IMEI=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	IMEI=$(echo $IMEI | grep -o "[0-9]\{15\}")
fi

if [ -n "$IMEI" ]; then
	IMEI=$(echo "$IMEI" | sed -e 's/"//g')
	IMEI=${IMEI:0:15}
else
	IMEI="Unknown"
fi

IDP=$(uci get modem.modem$CURRMODEM.idP)
IDV=$(uci get modem.modem$CURRMODEM.idV)

echo $IDV" : "$IDP > /tmp/msimdatax$CURRMODEM
echo "$IMEI" >> /tmp/msimdatax$CURRMODEM

lua $ROOTER/signal/celltype.lua "$MODEL" $CURRMODEM
source /tmp/celltype$CURRMODEM
rm -f /tmp/celltype$CURRMODEM

uci set modem.modem$CURRMODEM.celltype=$CELL
uci commit modem

$ROOTER/luci/celltype.sh $CURRMODEM

M2=$(echo "$OX" | sed -e "s/+CNUM: /+CNUM:,/g")
CNUM=$(echo "$M2" | awk -F[,] '/^\+CNUM:/ {print $3}')
if [ "x$CNUM" != "x" ]; then
	CNUM=$(echo ${CNUM%%$'\n'*} | sed -e 's/"//g')
else
	CNUM="*"
fi
CNUMx=$(echo "$M2" | awk -F[,] '/^\+CNUM:/ {print $2}')
if [ "x$CNUMx" != "x" ]; then
	CNUMx=$(echo ${CNUMx%%$'\n'*} | sed -e 's/"//g')
else
	CNUMx="*"
fi

NLEN=$(echo "$OX" | awk -F[,\ ] '/^\+CPBR:/ {print $4}')
if [ "x$NLEN" != "x" ]; then
	NLEN=$(echo "$NLEN" | sed -e 's/"//g')
else
	NLEN="14"
fi
echo 'NLEN="'"$NLEN"'"' > /tmp/namelen$CURRMODEM

ATCMDD="AT+CIMI"
OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
OX=$($ROOTER/common/processat.sh "$OX")
ERROR="ERROR"
if `echo ${OX} | grep "${ERROR}" 1>/dev/null 2>&1`
then
	IMSI="Unknown"
else
	OX=${OX//[!0-9]/}
	IMSIL=${#OX}
	IMSI=${OX:0:$IMSIL}
fi
echo "$IMSI" >> /tmp/msimdatax$CURRMODEM

ATCMDD="AT+CRSM=176,12258,0,0,10"
OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
OX=$($ROOTER/common/processat.sh "$OX")
ERROR="ERROR"
if `echo ${OX} | grep "${ERROR}" 1>/dev/null 2>&1`
then
	ICCID="Unknown"
else
	ICCID=$(echo "$OX" | awk -F[,\ ] '/^\+CRSM:/ {print $4}')
	if [ "x$ICCID" != "x" ]; then
		sstring=$(echo "$ICCID" | sed -e 's/"//g')
		length=${#sstring}
		xstring=
		i=0
		while [ $i -lt $length ]; do
			c1=${sstring:$i:1}
			let 'j=i+1'
			c2=${sstring:$j:1}
			xstring=$xstring$c2$c1
			let 'i=i+2'
		done
		ICCID=$xstring
	else
		ICCID="Unknown"
	fi
fi
echo "$ICCID" >> /tmp/msimdatax$CURRMODEM
echo "0" >> /tmp/msimdatax$CURRMODEM
echo "$CNUM" > /tmp/msimnumx$CURRMODEM
echo "$CNUMx" >> /tmp/msimnumx$CURRMODEM

mv -f /tmp/msimdatax$CURRMODEM /tmp/msimdata$CURRMODEM
mv -f /tmp/msimnumx$CURRMODEM /tmp/msimnum$CURRMODEM

