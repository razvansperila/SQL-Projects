SELECT * FROM sql_project.crash_reporting_drivers_data;

#creating a staging table

create table crash_reporting_drivers_staging
select *
from crash_reporting_drivers_data;

select *
from crash_reporting_drivers_staging;


#checking for doubles

select `report number`, count(`report number`)
from crash_reporting_drivers_staging
group by 1
having count(`report number`) > 1;

select *
from crash_reporting_drivers_staging
where `report number` = 'DM8479000T';

select concat(`report number`,`person id`), count(concat(`report number`,`person id`))
from crash_reporting_drivers_staging
group by 1
having count(concat(`report number`,`person id`)) > 1;


#fixing data types

select `crash date/time`, str_to_date(`crash date/time`, '%m/%d/%Y %H:%i')
from crash_reporting_drivers_staging;


update crash_reporting_drivers_staging
set `crash date/time` = str_to_date(`crash date/time`, '%m/%d/%Y %H:%i');

alter table crash_reporting_drivers_staging
modify `crash date/time` datetime;


#checking for inconsistencies to standardize

select distinct `agency name`
from crash_reporting_drivers_staging
order by 1;

select *
from crash_reporting_drivers_staging
where `agency name` like '%gaithersburg%';

update crash_reporting_drivers_staging
set `agency name` = 'Gaithersburg Police Depar'
where `agency name` = 'GAITHERSBURG';

update crash_reporting_drivers_staging
set `agency name` = 'Montgomery County Police'
where `agency name` = 'MONTGOMERY';

update crash_reporting_drivers_staging
set `agency name` = 'Takoma Park Police Depart'
where `agency name` = 'TAKOMA';


select *
from crash_reporting_drivers_staging;

select distinct `collision type`
from crash_reporting_drivers_staging
order by 1;

update crash_reporting_drivers_staging
set `collision type` = upper(`collision type`);


select distinct weather
from crash_reporting_drivers_staging
order by 1;

update crash_reporting_drivers_staging
set weather = 'RAIN'
where weather like 'RAIN%';

update crash_reporting_drivers_staging
set weather = upper(weather);


select distinct `Surface Condition`
from crash_reporting_drivers_staging
order by 1;


update crash_reporting_drivers_staging
set `Surface Condition` = 'WATER(STANDING/MOVING)'
where `Surface Condition` like 'water%';


update crash_reporting_drivers_staging
set `Surface Condition` = upper(`Surface Condition`);


select distinct light
from crash_reporting_drivers_staging
order by 1;

update crash_reporting_drivers_staging
set light = 'Dark - Unknown Lighting'
where light = 'DARK -- UNKNOWN LIGHTING';


update crash_reporting_drivers_staging
set light = upper(light);


select distinct `Traffic Control`
from crash_reporting_drivers_staging
order by 1;

update crash_reporting_drivers_staging
set `Traffic Control` = upper(`Traffic Control`);



select distinct `Driver Substance Abuse`
from crash_reporting_drivers_staging
order by 1;

update crash_reporting_drivers_staging
set `Driver Substance Abuse` = upper(`Driver Substance Abuse`);


select distinct `Non-Motorist Substance Abuse`
from crash_reporting_drivers_staging
order by 1;

update crash_reporting_drivers_staging
set `Non-Motorist Substance Abuse` = upper(`Non-Motorist Substance Abuse`);


select distinct `Driver Distracted By`
from crash_reporting_drivers_staging
order by 1;

update crash_reporting_drivers_staging
set `Driver Distracted By` = upper(`Driver Distracted By`);

select *
from crash_reporting_drivers_staging;


select distinct `Vehicle Body Type`
from crash_reporting_drivers_staging
order by 1;


update crash_reporting_drivers_staging
set `Vehicle Body Type` = upper(`Vehicle Body Type`);



#exploratory data analysis

select *
from crash_reporting_drivers_staging;


#number of incidents reported by year

select max(year(`crash date/time`)), min(year(`crash date/time`))
from crash_reporting_drivers_staging;

select year(`crash date/time`) as `year`, count(distinct `report number`) as crash
from crash_reporting_drivers_staging
group by 1
order by 2 desc;



#year after year percentage of incidents growth
select year, round((crash / lag(crash) over(order by year) - 1) * 100, 2) as percentage_incidents_growth
from(
	select year(`crash date/time`) as `year`, count(distinct `report number`) as crash
	from crash_reporting_drivers_staging
	group by 1
    ) as sub_year_crash;
    
    

#in which month of the year the most incidents happen

select month(`crash date/time`) as `month`, count(distinct `report number`) as crash
from crash_reporting_drivers_staging
group by 1
order by 2 desc;


#what are the most common reasons drivers are distracted when involved in an incident

select `Driver Distracted By`, count(`Driver Distracted By`)
from crash_reporting_drivers_staging
group by 1
order by 2 desc;


#are there any hours when the most incidents take place?

select hour(`crash date/time`), count(distinct `report number`)
from crash_reporting_drivers_staging
group by 1
order by 2 desc;



#ranking from which states are the drivers who cause the most and the fewest incidents

with cte_state as
(
select *, 'Most Crashes' as Label,
	dense_rank() over(order by crash desc) as ranking
    from(
		select `drivers license state` as state, count(`drivers license state`) as crash
		from crash_reporting_drivers_staging
		where `Driver At Fault` = 'Yes'
		and `drivers license state` <> ''
		group by 1
        ) as sub_state
        
union

select *, 'Least Crashes' as Label,
	dense_rank() over(order by crash) as ranking
    from(
		select `drivers license state` as state, count(`drivers license state`) as crash
		from crash_reporting_drivers_staging
		where `Driver At Fault` = 'Yes'
		and `drivers license state` <> ''
		group by 1
        ) as sub_state
)
select state, label, ranking
from cte_state
where ranking < 4;



#percentage of drivers at fault who were under the influence of substances (does not include drivers suspected of use of substances)

select round(count(*) / (select count(*) from crash_reporting_drivers_staging) * 100, 2) as percentage
from(
	select *
	from crash_reporting_drivers_staging
	where (`Driver Substance Abuse` like '%ALCOHOL%' or `Driver Substance Abuse` like '%DRUG%' or `Driver Substance Abuse` like '%COMBINED SUBSTANCES%')
	and `Driver Substance Abuse` like '%PRESENT%'
	and `driver at fault` = 'Yes'
    )sub_drivers
	;


#average number of cars involed in a crash

select avg(cnt)
from(
	select `report number`, count(`report number`) as cnt
	from crash_reporting_drivers_staging
	group by 1
    )sub_crashes;


select *
from crash_reporting_drivers_staging;


#percentage of casualties of people involved in a crash per year

select cas.year, round(casualties / crashes * 100, 2) as perc_of_casualties
from
	(
	select year(`crash date/time`) as `year`, count(*) as casualties
	from crash_reporting_drivers_staging
	where `ACRS Report Type` = 'Fatal Crash'
	group by 1
    ) cas
join
	(
	select year(`crash date/time`) as `year`, count(distinct `report number`) as crashes
	from crash_reporting_drivers_staging
	group by 1
    ) cra
using(`year`)
order by cas.year;



#years with higher casualties than average

create temporary table percentage_casualties_yearly
select cas.year, round(casualties / crashes * 100, 2) as perc_of_casualties
from
	(
	select year(`crash date/time`) as `year`, count(*) as casualties
	from crash_reporting_drivers_staging
	where `ACRS Report Type` = 'Fatal Crash'
	group by 1
    ) cas
join
	(
	select year(`crash date/time`) as `year`, count(distinct `report number`) as crashes
	from crash_reporting_drivers_staging
	group by 1
    ) cra
using(`year`)
order by cas.year;


select `year`
from(
	select *, round(avg(perc_of_casualties) over(), 2) as cas_avg
	from percentage_casualties_yearly
    )sub_avg_cas
where perc_of_casualties > cas_avg
;



















