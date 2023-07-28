#!/bin/bash

source ./jobs.sh

# test
# SLACK_NOTICE_URL=http://127.0.0.1:8080
# LEGAL_WORKING_DAYS='08-01'
# OFFICIAL_HOLIDAYS='08-01'
# QWEATHER_URL='https://devapi.qweather.com/v7/weather/now?location=113.3842,22.9377&key='
# JOB1='10:50:00///slackNotice///NOTICE_TEXT=点外卖啦！'
# JOB2='10:20:00///specialDayOfWeekSlackNotice///NOTICE_TEXT=周三啦;SPECIAL_DOW=3;'
# JOB3='10:40:00///extremeWeatherSlackNotice///NOTICE_TEXT=今天天气不佳，担心送餐高峰影响的话，现在可以点外卖了～;'

# 时区
TZ=UTC-8
# 当前是否为工作日
IS_WORK_DAY=false
# 当前月份+日期（MM-DD）
MONTH_AND_DAY=$(TZ=$TZ date +%m-%d)
# 星期几 0-6（星期日到星期六）
DAY_WEEK=$(TZ=$TZ date +%w)
echo "$(date +%FT%H:%M:%SZ) MONTH_AND_DAY: $MONTH_AND_DAY"
echo "$(date +%FT%H:%M:%SZ) DAY_WEEK: $DAY_WEEK"

# 周一至周五为工作日
if [[ $DAY_WEEK -ne 0 && $DAY_WEEK -ne 6 ]];then
	echo "$(date +%FT%H:%M:%SZ) normal weekday, set IS_WORK_DAY to true"
	IS_WORK_DAY=true
fi

# 判断是否为法定工作日
for dat in $LEGAL_WORKING_DAYS
do
	if [[ $dat = $MONTH_AND_DAY ]];then
		echo "$(date +%FT%H:%M:%SZ) legal working days, set IS_WORK_DAY to true"
		IS_WORK_DAY=true;
	fi
done

# 判断是否为法定假期
for dat in $OFFICIAL_HOLIDAYS
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

# 最大执行任务数量
MAX_JOB_COUNT=1000
# 任务列表
JOBS_ARR=()

# 当前天气信息
WEATHER_INFO=$(curl -L -X GET --compressed $QWEATHER_URL)
echo "$(date +%FT%H:%M:%SZ) WEATHER_INFO: $WEATHER_INFO";
WEATHER_TEXT=$(echo $WEATHER_INFO | jq -r ".now.text")
echo "$(date +%FT%H:%M:%SZ) WEATHER_TEXT: $WEATHER_TEXT";

for i in $(seq 1 $MAX_JOB_COUNT)
do
	job=`eval echo '$'"JOB$i"`
	if [[ -n $job ]];
	then
		echo "$(date +%FT%H:%M:%SZ) job: $job"
		JOBS_ARR+=($job)
		# JOBS_ARR[$[i-1]]=$job
		# JOBS_ARR[${#JOBS_ARR[@]}]=$job
	fi
done

DONE_JOBS_ARR=()
while [[ ${#DONE_JOBS_ARR[@]} -ne ${#JOBS_ARR[@]} ]];
do
	for job in ${JOBS_ARR[@]}
	do
		currentTs=$(TZ=$TZ date +%s)
		isDone=$(echo ${DONE_JOBS_ARR[@]} | grep -o "$job" | wc -w | xargs)
		echo "is done: $isDone"
		if [[ $isDone == "1" ]];
		then
			continue
		fi
		echo "$(date +%FT%H:%M:%SZ) job: $job"
		jobArr=(${job//\/\/\// })
		ts=${jobArr[0]}
		targetTs=$(TZ=$TZ date -d "$(TZ=$TZ date +%F" $ts")" +%s)
		method=${jobArr[1]}
		if [[ -n ${jobArr[2]} ]];
		then
			# !!这里直接执行eval存在危险
			eval ${jobArr[2]}
		fi
		echo "$(date +%FT%H:%M:%SZ) current time: $currentTs"
		echo "$(date +%FT%H:%M:%SZ) targetTs: $targetTs"
		echo "$(date +%FT%H:%M:%SZ) method: $method"

		if [[ $currentTs -ge $targetTs ]];
		then
			case $method in
				slackNotice)
					slackNotice
				;;
				specialDayOfWeekSlackNotice)
					specialDayOfWeekSlackNotice
				;;
				extremeWeatherSlackNotice)
					extremeWeatherSlackNotice
				;;
				specialDayOfWeekAndExtreWeatherSlackNotice)
					specialDayOfWeekAndExtreWeatherSlackNotice
				;;
			esac
			# 记录已经完成的任务
			DONE_JOBS_ARR+=($job)
		fi
	done

	for j in ${DONE_JOBS_ARR[@]}
	do
		echo "$(date +%FT%H:%M:%SZ) done job: $j"
	done

	if [[ ${#DONE_JOBS_ARR[@]} != ${#JOBS_ARR[@]} ]];
	then
		sleep 60
	fi
done
