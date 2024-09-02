
#horse racing project

SELECT *
FROM horse_race_project;

#creating a staging table

create table horse_race_project_staging
select *
from horse_race_project;

SELECT *
FROM horse_race_project_staging;

#modify data type and format for column date

select `date`, str_to_date(`date`, '%d/%m/%Y')
from horse_race_project_staging;

update horse_race_project_staging
set `date` = str_to_date(`date`, '%d/%m/%Y');

alter table horse_race_project_staging
modify column `date` date;

#checking for doubles

select uid, count(uid)
from horse_race_project_staging
group by 1
having count(uid) > 1;

#checking to see if the data set requires any standardization

select *
from horse_race_project_staging;

select distinct tipster
from horse_race_project_staging;

select distinct track
from horse_race_project_staging
order by 1;

select horse, count(horse) as adc
from horse_race_project_staging
group by 1
order by 1;

select distinct `bet type`
from horse_race_project_staging;

select distinct odds
from horse_race_project_staging
order by 1;

select distinct result
from horse_race_project_staging;

select distinct tipsteractive
from horse_race_project_staging;

#standardized tipsteractive column to be in proper case to look like the other columns

select tipsteractive,
	concat(
			upper(substring(tipsteractive, 1, 1)),
			lower(substring(tipsteractive, 2, 10))
          )
from horse_race_project_staging;

update horse_race_project_staging
set tipsteractive = concat(upper(substring(tipsteractive, 1, 1)),lower(substring(tipsteractive, 2, 10)));


select *
from horse_race_project_staging;


#exploratory data analysis

#how many bets each tipster has and their win/lose ratio

select tipster, count(tipster) as bets,
	round(count(case when result = 'Win' then 1 end) / count(*) * 100, 2) as perc_won,
    round(count(case when result = 'Lose' then 1 end) / count(*) * 100, 2) as perc_lost
from horse_race_project_staging
group by 1;



#top 3 tipsters by percentage won and lost

with cte_tipster as
(
select *, rank() over(order by perc_won desc) as ranking
	from(
			select tipster,
				round(count(case when result = 'Win' then 1 end) / count(*) * 100, 2) as perc_won,
				round(count(case when result = 'Lose' then 1 end) / count(*) * 100, 2) as perc_lost
			from horse_race_project_staging
			group by 1
		) sub_tipsters
)
select tipster, perc_won as percenatge, 'won' as label, ranking
from cte_tipster
where ranking < 4

union

select tipster, perc_lost as percenatge, 'lost' as label, ranking
from
(
	(
	select *, rank() over(order by perc_lost desc) as ranking
		from(
				select tipster,
					round(count(case when result = 'Win' then 1 end) / count(*) * 100, 2) as perc_won,
					round(count(case when result = 'Lose' then 1 end) / count(*) * 100, 2) as perc_lost
				from horse_race_project_staging
				group by 1
			) sub_tipsters
	)
) big_sub_ipster
where ranking < 4;



select *
from horse_race_project_staging;

#tipsters consistency over the years

select tipster, year(`date`), count(*)
from horse_race_project_staging
group by 1, 2
order by 1, 2;


#favorite bet type of every tipster

with cte_tipster as
(
select *
	from(
			select tipster, `bet type` as bet_type_ew, count(`bet type`) as cnt_ew
			from horse_race_project_staging
			where `bet type` = 'Each Way'
			group by 1, 2
			order by 1, 2
		)each_way
join 
	(select *
	from(
			select tipster, `bet type` as bet_type_w, count(`bet type`) as cnt_w
			from horse_race_project_staging
			where `bet type` = 'Win'
			group by 1, 2
			order by 1, 2
		)sub_win
	)win 
using(tipster)
)
select tipster,
	case
	when cnt_ew > cnt_w then bet_type_ew
    when cnt_w > cnt_ew then bet_type_w
    else 'no favorite' end as favorite_bet_type
from cte_tipster;


 
 #tipster's avg and median odds for win and lose
 
select tipster, result, round(avg(odds),2) as avg_odds,
	round((max(odds) + min(odds)) / 2, 2) as median_odds
from horse_race_project_staging
group by 1, 2
order by 1, 2;


#tipsters activity status

select tipster, tipsteractive
from horse_race_project_staging
group by 1, 2;


#prcentage of tipsters active and inactive

select  round(count(case when tipsteractive = 'True' then 1 end) / count(*) * 100, 2) as `active`,
		round(count(case when tipsteractive = 'False' then 1 end) / count(*) * 100, 2) as `inactive`
from (
		select tipster, tipsteractive
		from horse_race_project_staging
		group by 1, 2
	) tipster_activity_sub;
    
    
    
select *
from horse_race_project_staging;



#most active tipster per year 

select `year`, tipster, bets
from(
		select *, max(bets) over(partition by year order by bets desc) as `max`
		from(
				select year(`date`) as year, tipster, count(*) bets
				from horse_race_project_staging
				group by 1, 2
			) sub_bets
	) big_sub_bets
    where bets = `max`;


#top 10 horses by races won

select horse, count(*)
from horse_race_project_staging
where result = 'Win'
group by 1
order by 2 desc
limit 10;


#top 5 odds with most wins and loses

select *
from(
	select odds, result, count(result)
	from horse_race_project_staging
	where result = 'Win'
	group by 1, 2
	order by count(result) desc
    limit 5
	) win

union

select *
from(
	select odds, result, count(result)
	from horse_race_project_staging
	where result = 'Lose'
	group by 1, 2
	order by count(result) desc
    limit 5
	) lose;
    
    
drop table horse_race_project;

rename table horse_race_project_staging to horse_race_project;











