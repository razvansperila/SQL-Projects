select *
from call_center_data;



create table call_center_staging
select *
from call_center_data;

#data cleaning and standardization

select `call id`, count(`call id`)
from call_center_staging
group by 1
having count(`call id`) > 1;



select *
from call_center_staging;

select distinct resolved
from call_center_staging;

alter table call_center_staging
drop column `MyUnknownColumn`;



alter table call_center_staging
modify column `date` date; 


alter table call_center_staging
modify column `time` time; 


alter table call_center_staging
modify column `Speed of answer in seconds` int;

update call_center_staging
set `Speed of answer in seconds` = null
where `Speed of answer in seconds` = '';


select *
from call_center_staging;


alter table call_center_staging
modify column `AvgTalkDuration` time; 


update call_center_staging
set `Satisfaction rating` = null
where `Satisfaction rating` = '';


alter table call_center_staging
modify column `Satisfaction rating` int;


select *
from call_center_staging
where `Answered (Y/N)` = 'N'
and `AvgTalkDuration` <> '00:00:00';


select *
from call_center_staging
where `Answered (Y/N)` = 'N'
and `Speed of answer in seconds` is not null;


#exploratory data analysis

select *
from call_center_staging;


#how many calls do agents receive per month

select month(`date`) as `month`, agent, count(`call id`) as calls
from call_center_staging
group by 1, 2;



#which topic has the most requests

select topic, count(topic) as cnt_topic,
	count(case when resolved = 'Y' then 1 end) as resolved,
    count(case when resolved = 'N' then 1 end) as not_resolved
from call_center_staging
group by 1;




#which agent has the most answered and resolved calls procentual and avg satisfaction rating

select month(`date`) as `month`, agent,
	round(count(case when `Answered (Y/N)` = 'Y' then 1 end) / count(*) * 100, 2) as perc_answered_calls,
    round(count(case when resolved = 'Y' then 1 end) / count(*) * 100, 2) as perc_resolved_calls,
    round(avg(`Satisfaction rating`), 2) as avg_rating
from call_center_staging
group by 1, 2;


#what is the avg talk duration for every topic

select topic, round(avg(AvgTalkDuration) / 60, 2) avg_talk_duration_minutes
from call_center_staging
group by 1;


select *
from call_center_staging;

#avg time between the start of the calls for every agent(start time of the call to start time of the next call)

with cte_data as
(
select *, timestampdiff(second, `call`, `next_call`) as time_in_seconds
from(
	select agent, `date`, `time` as `call`,
		lead(`time`) over(partition by agent order by `date`, `time`) as next_call
	from call_center_staging
	where `Answered (Y/N)` = 'Y'
    ) sub_data
)
select agent, month(`date`) as `month`, round(avg(time_in_seconds) / 60, 2) as avg_minutes_between_calls,
round(((max(time_in_seconds) + min(time_in_seconds)) / 2) / 60, 2) as median_minutes_between_calls
from cte_data
where time_in_seconds > 0 
group by 1, 2;


#calls per day vs answered calls per day by agent

select day(`date`) as `month`, agent, count(*) as calls, count(case when `Answered (Y/N)` = 'Y' then 1 end) as answered_calls
from call_center_staging
group by 1, 2;

select agent, round(avg(calls)) avg_calls, round(avg(answered_calls)) as avg_answered
from(
	select day(`date`) as `month`, agent, count(*) as calls, count(case when `Answered (Y/N)` = 'Y' then 1 end) as answered_calls
	from call_center_staging
	group by 1, 2
    ) sub_data
group by 1;




#avg time between calls by agent (end of the call to start of the next call)


with cte_data as
(
select agent, timestampdiff(minute, end_time, next_call) as time_in_minutes
from(
	select agent, `date`, `time`, sec_to_time((time_to_sec(`time`)+time_to_sec(AvgTalkDuration))) as end_time,
		lead(time) over(partition by agent order by `date`, `time`) as next_call
	from call_center_staging
	)sub_data
)
select agent, avg(time_in_minutes) as avg_time
from cte_data
where time_in_minutes > 0
group by 1;


select *
from call_center_staging;

drop table call_center_data;

rename table call_center_staging to call_center_data;


















