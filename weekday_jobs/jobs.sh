#!/bin/bash

# 发送slack消息
function slackNotice () {
	echo "$(date +%FT%H:%M:%SZ) NOTICE_TEXT: $NOTICE_TEXT";
	RES=$(curl -X POST \
	-H 'Content-type: application/json' \
	--data '{"text":"'$NOTICE_TEXT'"}' \
	$SLACK_NOTICE_URL)
	echo "$(date +%FT%H:%M:%SZ) slackNotice result: $RES";
}

# 指定星期几发送slack通知
function specialDayOfWeekSlackNotice () {
	if [[ $(TZ=$TZ date +%w) -eq $SPECIAL_DOW ]];
	then
		echo "$(date +%FT%H:%M:%SZ) SPECIAL_DOW: $SPECIAL_DOW";
		slackNotice
	fi
}

# 极端天气发送slack通知
function extremeWeatherSlackNotice () {
	IS_EXTREME_WEATHER_DAY=false
	for text in $EXTREME_WEATHER_TEXTS
	do
		if [[ $text = $WEATHER_TEXT ]];then
			echo "$(date +%FT%H:%M:%SZ) extreme weather desc: $WEATHER_TEXT";
			IS_EXTREME_WEATHER_DAY=true
		fi
	done
	echo "$(date +%FT%H:%M:%SZ) IS_EXTREME_WEATHER_DAY: $IS_EXTREME_WEATHER_DAY";
	if $IS_EXTREME_WEATHER_DAY;
	then
		slackNotice
	fi
}

# 极端天气下且指定周几发送slack通知
function specialDayOfWeekAndExtreWeatherSlackNotice () {
	IS_EXTREME_WEATHER_DAY=false
	for text in $EXTREME_WEATHER_TEXTS
	do
		if [[ $text = $WEATHER_TEXT ]];then
			echo "$(date +%FT%H:%M:%SZ) extreme weather desc: $WEATHER_TEXT";
			IS_EXTREME_WEATHER_DAY=true
		fi
	done
	echo "$(date +%FT%H:%M:%SZ) IS_EXTREME_WEATHER_DAY: $IS_EXTREME_WEATHER_DAY";
	if $IS_EXTREME_WEATHER_DAY;then
		if [[ $(TZ=$TZ date +%w) -eq $SPECIAL_DOW ]];
		then
			slackNotice
		fi
	fi
}