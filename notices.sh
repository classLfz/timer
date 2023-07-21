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

# 美团周三外卖节
function wedMeituanNotice () {
	if [[ $(TZ=$TZ date +%w) -eq 3 ]];then
		echo "$(date +%FT%H:%M:%SZ) wednesday, here is an meituan notice";
		echo "$(date +%FT%H:%M:%SZ) MEITUAN_HB_URL: $MEITUAN_HB_URL"
		RES=$(curl -X POST \
		-H 'Content-type: application/json' \
		--data '{"text":"今天周三，美团外卖节 点我领取大额红包'$MEITUAN_HB_URL'"}' \
		$NOTICE_URL)
		echo "$(date +%FT%H:%M:%SZ) wedMeituanNotice result: $RES";
	fi
}

# 美团18号满38-18活动
function eighteenMeituanNotice () {
	if [[ $(TZ=$TZ date +%d) = "18" ]];then
		RES=$(curl -X POST \
		-H 'Content-type: application/json' \
		--data '{"text":"今天18号，美团神券节，是用38-18的日子啦"}' \
		$NOTICE_URL)
		echo "$(date +%FT%H:%M:%SZ) eighteenMeituanNotice result: $RES";
	fi
}
