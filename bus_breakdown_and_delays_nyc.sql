
#bus breakdown and delays nyc project

select *
from bus_breakdown_and_delays_nyc;


CREATE TABLE `bus_breakdown_and_delays_nyc_staging` (
  `School_Year` text,
  `Busbreakdown_ID` int DEFAULT NULL,
  `Run_Type` text,
  `Bus_No` text,
  `Route_Number` text,
  `Reason` text,
  `Schools_Serviced` text,
  `Occurred_On` text,
  `Created_On` text,
  `Boro` text,
  `Bus_Company_Name` text,
  `How_Long_Delayed` text,
  `Number_Of_Students_On_The_Bus` int DEFAULT NULL,
  `Has_Contractor_Notified_Schools` text,
  `Has_Contractor_Notified_Parents` text,
  `Have_You_Alerted_OPT` text,
  `Informed_On` text,
  `Incident_Number` text,
  `Last_Updated_On` text,
  `Breakdown_or_Running_Late` text,
  `School_Age_or_PreK` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into bus_breakdown_and_delays_nyc_staging
select *
from bus_breakdown_and_delays_nyc;


#checking for doubles

select Busbreakdown_ID, count(Busbreakdown_ID)
from bus_breakdown_and_delays_nyc_staging
group by 1
having count(Busbreakdown_ID) = 1;


#changing column's datatype where needed and formatting

select occurred_on, str_to_date(occurred_on, '%m/%d/%Y %H:%i')
from bus_breakdown_and_delays_nyc_staging;

select *
from bus_breakdown_and_delays_nyc_staging;

update bus_breakdown_and_delays_nyc_staging
set occurred_on = str_to_date(occurred_on, '%m/%d/%Y %H:%i');

alter table bus_breakdown_and_delays_nyc_staging
modify occurred_on datetime;

select created_on, str_to_date(created_on, '%m/%d/%Y %H:%i')
from bus_breakdown_and_delays_nyc_staging;

update bus_breakdown_and_delays_nyc_staging
set created_on = str_to_date(created_on, '%m/%d/%Y %H:%i');

alter table bus_breakdown_and_delays_nyc_staging
modify created_on datetime;


update bus_breakdown_and_delays_nyc_staging
set informed_on = str_to_date(informed_on, '%m/%d/%Y %H:%i');

alter table bus_breakdown_and_delays_nyc_staging
modify informed_on datetime;


update bus_breakdown_and_delays_nyc_staging
set Last_Updated_On = str_to_date(Last_Updated_On, '%m/%d/%Y %H:%i');

alter table bus_breakdown_and_delays_nyc_staging
modify Last_Updated_On datetime;


#standardization of data

select *
from bus_breakdown_and_delays_nyc_staging;

select Bus_Company_Name, COUNT(Bus_Company_Name)
from bus_breakdown_and_delays_nyc_staging
GROUP BY 1
order by 1;

update bus_breakdown_and_delays_nyc_staging
set reason = 'Will not Start'
where reason = 'Won`t Start';


update bus_breakdown_and_delays_nyc_staging
set Bus_Company_Name = 'PRIDE TRANSPORTATION (SCH AGE)'
where Bus_Company_Name like 'PRIDE%';
#i used the same block of code to update all the company names that needed standardization


select Bus_Company_Name, COUNT(Bus_Company_Name)
from bus_breakdown_and_delays_nyc_staging
where Bus_Company_Name LIKE 'PHIL%'
GROUP BY 1;

SELECT DISTINCT BORO
FROM bus_breakdown_and_delays_nyc_staging
where Bus_Company_Name = 'Phillip Bus Service Inc.';





select *
from bus_breakdown_and_delays_nyc_staging;


#changing last_update_on values to null where values were 01-01-1900 
update bus_breakdown_and_delays_nyc_staging
set Last_Updated_On = null
where year(Last_Updated_On) = 1900;


#trying to find a way to complete blank spaces in how_long_delayed column
select bus_company_name, How_Long_Delayed, count(How_Long_Delayed)
from bus_breakdown_and_delays_nyc_staging
group by 1,2
order by 1,2;





#exploratory data analysis

select *
from bus_breakdown_and_delays_nyc_staging;



#number of incidents by bus company

select Bus_Company_Name, count(*)
from bus_breakdown_and_delays_nyc_staging
group by 1
order by 2 desc;

select Bus_Company_Name, school_year, count(*)
from bus_breakdown_and_delays_nyc_staging
group by 1,2
order by 1,2;




#number of incidents by school year

select school_year, count(*) as incidents, count(distinct Bus_Company_Name) as bus_companies
from bus_breakdown_and_delays_nyc_staging
group by 1
order by 2 desc;




#percentage breakdown vs running late by bus company

select Bus_Company_Name,
	round(count(case when Breakdown_or_Running_Late = 'Breakdown' then 1 end) / count(*) * 100) as breakdown_perc,
    round(count(case when Breakdown_or_Running_Late = 'Running Late' then 1 end) / count(*) * 100) as running_late_perc
from bus_breakdown_and_delays_nyc_staging
	group by 1
    order by 1;




#main reason for incidents by bus company

select bus_company_name,
	case when main_reason = cnt_reason then reason end as reason
    from(
		select *, max(cnt_reason) over(partition by Bus_Company_Name) as main_reason
		from(
			select Bus_Company_Name, reason, count(reason) as cnt_reason
			from bus_breakdown_and_delays_nyc_staging
			group by 1,2
			order by 1,2
			)as sub_reason
		) as big_sub_reason
	group by 1,2
    having reason is not null
;



#main reason for incidents by bus company and percentage of main incident of total incidents per company 

select bus_company_name,
	case when main_reason = cnt_reason then reason end as reason,
    round(main_reason / cnt_by_company * 100, 2) as perc_of_reason_per_company
    from(
		select *,
			max(cnt_reason) over(partition by Bus_Company_Name) as main_reason,
			sum(cnt_reason) over(partition by Bus_Company_Name) as cnt_by_company
		from(
			select Bus_Company_Name, reason, count(reason) as cnt_reason
			from bus_breakdown_and_delays_nyc_staging
			group by 1,2
			order by 1,2
			)as sub_reason
		) as big_sub_reason
	group by 1,2,3
    having reason is not null;




select *
from bus_breakdown_and_delays_nyc_staging;


#number of incidents by run type

select run_type, count(*)
from bus_breakdown_and_delays_nyc_staging
group by 1
order by 2 desc;


#number of incidents by time delayed

select how_long_delayed, count(*)
from bus_breakdown_and_delays_nyc_staging
group by 1
order by 2 desc;



#number of incidents by boro

select boro, count(*)
from bus_breakdown_and_delays_nyc_staging
group by 1
order by 2 desc;


drop table bus_breakdown_and_delays_nyc;

rename table bus_breakdown_and_delays_nyc_staging to bus_breakdown_and_delays_nyc;


select *
from bus_breakdown_and_delays_nyc;












