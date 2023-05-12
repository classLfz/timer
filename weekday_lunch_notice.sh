#!/bin/bash

###
# 脚本用于提醒工作日时间中午定外卖
# 由于github action的资源占用比较严重，脚本需要比预期时间要提前15分钟左右进入执行队列
# 该脚本优先判断是否为工作日，如果为工作日，往下执行，否则中断执行
# 工作日则设置轮询定时器，隔一段时间判断是否抵达目标时间点，同时记录重试次数
# 无论是抵达预期时间点还是重试次数抵达最大值，都执行目标任务
# 预期时间点会根据查询当地天气情况有变动，如果遇上下雨等天气，则提前提醒点外卖
###

source ./notices.sh

# 判断通知的URL变量是否存在
if [[ $NOTICE_URL = "" ]];then
	echo "$(date +%FT%H:%M:%SZ) miss NOTICE_URL variable"
	exit 0;
fi

# 时区
TZ=UTC-8
# 当前是否为工作日
IS_WORK_DAY=false
# 当前月份+日期（MM-DD）
MONTH_AND_DAY=$(TZ=$TZ date +%m-%d)
# 星期几 0-6（星期日到星期六）
DAY_WEEK=$(TZ=$TZ date +%w)
# 法定工作日（2023年下半年, MM-DD）
LEGAL_WORKING_DAYS='06-25 10-07 10-08'
# 法定假期(2023年下半年, MM-DD)
OFFICIAL_HOLIDAYS='06-22 06-23 06-24 09-29 10-02 10-03 10-04 10-05 10-06'
echo "$(date +%FT%H:%M:%SZ) MONTH_AND_DAY: $MONTH_AND_DAY"
echo "$(date +%FT%H:%M:%SZ) DAY_WEEK: $DAY_WEEK"

# 周一至周五为工作日
if [[ $DAY_WEEK -ne 0 && $DAY_WEEK -ne 6 ]];then
	echo "$(date +%FT%H:%M:%SZ) normal weekday, set IS_WORK_DAY to true"
	IS_WORK_DAY=true
fi

# 判断是否为法定工作日
for dat in LEGAL_WORKING_DAYS
do
	if [[ $dat = $MONTH_AND_DAY ]];then
		echo "$(date +%FT%H:%M:%SZ) legal working days, set IS_WORK_DAY to true"
		IS_WORK_DAY=true;
	fi
done

# 判断是否为法定假期
for dat in OFFICIAL_HOLIDAYS
do
	if [[ $dat = $MONTH_AND_DAY ]];then
		echo "$(date +%FT%H:%M:%SZ) official holidays, set IS_WORK_DAY to false"
		IS_WORK_DAY=false;
	fi
done

echo "$(date +%FT%H:%M:%SZ) IS_WORK_DAY: $IS_WORK_DAY"
if $IS_WORK_DAY;
then
	echo "$(date +%FT%H:%M:%SZ) 今天是打工人";
else
	echo "$(date +%FT%H:%M:%SZ) 今天是自由人";
	exit 0;
fi

# 重试次数
RETRY_COUNT=0
# 最大重试次数
MAX_RETRY_COUNT=50
# 休眠间隔
SLEEP_INTERVAL=59
# 到时间啦
IS_TIME=false
# 正常情况下，要到达时间(单位秒)
TARGET_TIME=$(TZ=$TZ date -d "$(TZ=$TZ date +%F" 10:50:00")" +%s)

# 当前天气信息（和风天气免费版）
WEATHER_INFO=$(curl -L -X GET --compressed $QWEATHER_URL)
echo "$(date +%FT%H:%M:%SZ) WEATHER_INFO: $WEATHER_INFO";
WEATHER_TEXT=$(echo $WEATHER_INFO | jq -r ".now.text")
echo "$(date +%FT%H:%M:%SZ) WEATHER_TEXT: $WEATHER_TEXT";
# 极端天气列表
EXTREME_WEATHER_TEXTS='强阵雨 雷阵雨 强雷阵雨 雷阵雨伴有冰雹 中雨 大雨 极端降雨 暴雨 大暴雨 特大暴雨 冻雨 中到大雨 大到暴雨 暴雨到大暴雨 大暴雨到特大暴雨 雨 小雪 中雪 大雪 暴雪 雨夹雪 雨雪天气 阵雨夹雪 阵雪 小到中雪 中到大雪 大到暴雪 阵雨夹雪'
# 极端天气下，提前提醒
IS_EXTREME_WEATHER_DAY=false
for text in $EXTREME_WEATHER_TEXTS
do
	if [[ $text = $WEATHER_TEXT ]];then
		echo "$(date +%FT%H:%M:%SZ) extreme weather desc: $WEATHER_TEXT";
		TARGET_TIME=$(TZ=$TZ date -d "$(TZ=$TZ date +%F" 10:40:00")" +%s)
		IS_EXTREME_WEATHER_DAY=true
	fi
done
echo "$(date +%FT%H:%M:%SZ) TARGET_TIME: $TARGET_TIME";

while [[ $IS_TIME = false && $RETRY_COUNT -lt $MAX_RETRY_COUNT ]];
do
	CURRENT_TIME=$(TZ=$TZ date +%s)
	echo "$(date +%FT%H:%M:%SZ) CURRENT_TIME: $CURRENT_TIME";
	if [[ $CURRENT_TIME -ge $TARGET_TIME ]];
	then
		echo "$(date +%FT%H:%M:%SZ) timeout, set IS_TIME to true"
		IS_TIME=true;
	else
		echo "$(date +%FT%H:%M:%SZ) sleep $SLEEP_INTERVAL s"
		sleep $SLEEP_INTERVAL;
	fi
	# 如果没有等到，也认为时间到了
	if [[ $RETRY_COUNT -gt $MAX_RETRY_COUNT && $IS_TIME = false ]];then
		echo "$(date +%FT%H:%M:%SZ) max retry, set IS_TIME to true"
		IS_TIME=true;
	fi
	if [[ $IS_TIME = false ]];then
		RETRY_COUNT=`expr $RETRY_COUNT + 1`;
		echo "$(date +%FT%H:%M:%SZ) RETRY_COUNT: $RETRY_COUNT";
	fi
done
echo "$(date +%FT%H:%M:%SZ) RETRY_COUNT: $RETRY_COUNT";
echo "$(date +%FT%H:%M:%SZ) MAX_RETRY_COUNT: $MAX_RETRY_COUNT";

if $IS_TIME;then
	echo "$(date +%FT%H:%M:%SZ) time to book lunch";
	bookLunchNotice
	# 美团周三外卖节
	if [[ $DAY_WEEK -eq 3 ]];then
		echo "$(date +%FT%H:%M:%SZ) wednesday, here is an meituan notice";
		wedMeituanNotice
	fi
	# 美团18号满38-18活动
	if [[ $(TZ=$TZ date +%d) = "18" ]];then
		echo "$(date +%FT%H:%M:%SZ) day 18th, here is an meituan notice";
		eighteenMeituanNotice
	fi
fi
