#!/bin/bash

function bookLunchNotice () {
	NOTICE_TEXT="干饭机器人提醒您：现在是点外卖时间~"
	if $IS_EXTREME_WEATHER_DAY;then
		NOTICE_TEXT="今天预报天气为\`$WEATHER_TEXT\`,干饭机器人提醒您：现在是点外卖时间~"
	fi
	echo "$(date +%FT%H:%M:%SZ) NOTICE_TEXT: $NOTICE_TEXT";
	RES=$(curl -X POST \
	-H 'Content-type: application/json' \
	--data '{"text":"'$NOTICE_TEXT'"}' \
	$NOTICE_URL)
	echo "$(date +%FT%H:%M:%SZ) bookLunchNotice result: $RES";
}

function wedMeituanNotice () {
	echo "$(date +%FT%H:%M:%SZ) MEITUAN_HB_URL: $MEITUAN_HB_URL"
	RES=$(curl -X POST \
	-H 'Content-type: application/json' \
	--data '{"text":"今天周三，美团外卖节 点我领取大额红包'$MEITUAN_HB_URL'"}' \
	$NOTICE_URL)
	echo "$(date +%FT%H:%M:%SZ) wedMeituanNotice result: $RES";
}

function eighteenMeituanNotice () {
	RES=$(curl -X POST \
	-H 'Content-type: application/json' \
	--data '{"text":"今天18号，美团神券节，是用38-18的日子啦"}' \
	$NOTICE_URL)
	echo "$(date +%FT%H:%M:%SZ) eighteenMeituanNotice result: $RES";
}
