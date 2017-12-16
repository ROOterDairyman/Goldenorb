#!/bin/sh

ROOTER=/usr/lib/rooter

CURRMODEM=$1
COMMPORT=$2

get_cell() {
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "cellinfo.gcom" "$CURRMODEM")
	O=$($ROOTER/common/processat.sh "$OX")
}
get_cell
CREG="+CEREG:"
LAC=$(echo "$O" | awk -F[,] '/\'$CREG'/ {printf "%s", toupper($3)}' | sed 's/[^A-F0-9]//g')
if [ "x$LAC" = "x" ]; then
	CREG="+CGREG:"
	LAC=$(echo "$O" | awk -F[,] '/\'$CREG'/ {printf "%s", toupper($3)}' | sed 's/[^A-F0-9]//g')
fi

if [ "x$LAC" != "x" ]; then
	LAC=$(printf "%04X" 0x$LAC)
	LAC_NUM=$(printf "%d" 0x$LAC)
else
	LAC="-"
	LAC_NUM="-"
fi
LAC_NUM="  ("$LAC_NUM")"
if [ "$CREG" = "+CEREG:" ]; then
	CID=$(echo "$O" | grep -o "+CEREG:.\{8,\}" | awk '{print substr(toupper($0),20)}' | grep -o "[0-9A-F]\{3,8\}")
else
	CID=$(echo "$O" | awk -F[,] '/\'$CREG'/ {printf "%s", toupper($4)}' | sed 's/[^A-F0-9]//g')
fi
if [ "x$CID" != "x" ]; then
	if [ ${#CID} -lt 3 ]; then
		LCID="-"
		LCID_NUM="-"
		RNC="-"
		RNC_NUM="-"
	else
		LCID=$(printf "%08X" 0x$CID)
		LCID_NUM=$(printf "%d" 0x$LCID)
		if [ "$CREG" = "+CEREG:" ]; then
			RNC=$(printf "${LCID:1:5}")
			CID=$(printf "${LCID:6:2}")
		else
			RNC=$(printf "${LCID:1:3}")
			CID=$(printf "${LCID:4:4}")
		fi
		RNC_NUM=$(printf "%d" 0x$RNC)
		RNC_NUM=" ($RNC_NUM)"
	fi

	CID_NUM=$(printf "%d" 0x$CID)
else
	LCID="-"
	LCID_NUM="-"
	RNC="-"
	RNC_NUM="-"
	CID="-"
	CID_NUM="-"
fi
CID_NUM="  ("$CID_NUM")"

echo 'LAC="'"$LAC"'"' > /tmp/cell$CURRMODEM.file
echo 'LAC_NUM="'"$LAC_NUM"'"' >> /tmp/cell$CURRMODEM.file
echo 'CID="'"$CID"'"' >> /tmp/cell$CURRMODEM.file
echo 'CID_NUM="'"$CID_NUM"'"' >> /tmp/cell$CURRMODEM.file
echo 'RNC="'"$RNC"'"' >> /tmp/cell$CURRMODEM.file
echo 'RNC_NUM="'"$RNC_NUM"'"' >> /tmp/cell$CURRMODEM.file



