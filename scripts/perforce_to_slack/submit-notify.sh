#!/bin/bash

cd $(dirname $0) && pwd

# デフォルト値
USERID=""
CHANGE=""
ENVFILE=""

while getopts u:c:e: optKey; do
	case "$optKey" in
		u)
			USERID="${OPTARG}";;
		c)
			CHANGE=${OPTARG};;
		e)
			ENVFILE=${OPTARG};;
	esac
done

if [[ ! -f "$ENVFILE" ]]; then
    echo "エラー: $ENVFILE が見つかりません" >&2
    exit 1
fi

source "$ENVFILE"

yes $PS | p4 -u $USER login

message="<!channel>\n"

message+=$USERID
message+="さんが submit しました\n"

description=$(p4 describe -f -s $CHANGE 2>&1)

message+="\n\n"
message+="*変更内容：*\n" 
message+='```'
message+=$description
message+='```'


text="{\"text\":\"${message}\"}"

echo "*** send message ***"
echo $text
echo "*** url ***"
echo $CHANNEL

curl -X POST --data "$text" $CHANNEL