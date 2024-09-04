
select *
from pokemon_project;

#creating a staging table and adding an id column because number column has values that refer to the same pokemon
#(same number means the pokemon has multiple forms)

create table pokemon_project_staging
select *, row_number() over() as id
from pokemon_project;


select *
from pokemon_project_staging;

alter table pokemon_project_staging
modify id int;

alter table pokemon_project_staging
modify id int first;


#checking for doubles


select concat(`number`,`name`) as target, count(concat(`number`,`name`)) as count_target
from pokemon_project_staging
group by 1
having count_target > 1;


select `name`, count(`name`)
from pokemon_project_staging
group by 1
having count(`name`) > 1;

#checking if coumns need any standardization

select distinct type1
from pokemon_project_staging
order by 1;

select type1, count(type1)
from pokemon_project_staging
group by 1
order by 1;

update pokemon_project_staging
set type1 = 'Grass'
where type1 = 'Graass';

select distinct type2
from pokemon_project_staging
order by 1;

select distinct legendary
from pokemon_project_staging;


#changing legendary column in proper case to match the other columns

select legendary,
	concat(
			upper(substring(legendary, 1, 1)),
            lower(substring(legendary, 2))
		  )
from pokemon_project_staging;

update pokemon_project_staging
set legendary = concat(
			upper(substring(legendary, 1, 1)),
            lower(substring(legendary, 2))
						);


#exploratory data analysis

select *
from pokemon_project_staging;


#pokemons with higher total score than average

select `name`
from pokemon_project_staging
where total > (select avg(total) from pokemon_project_staging);


#the most powerful pokemons for each type1. if there is a tie, all pokemons sharing the same rating are displayed


select type1, `name`
from(
		select type1, `name`, total,
			rank() over(partition by type1 order by total desc) as ranking
		from pokemon_project_staging
	) sub_pokemon
    where ranking < 2
    order by 1, 2;


#the best and worst rated pokemon of each generation. if there is a tie, all pokemons sharing the same generation are displayed

with cte_pokemon as
(
select *, 'Best' as label
from(
		select generation, `name`, total,
			rank() over(partition by generation order by total desc) as ranking
		from pokemon_project_staging
	)sub_best
    where ranking < 2

union

select *, 'Worst' as label
from(
		select generation, `name`, total,
			rank() over(partition by generation order by total) as ranking
		from pokemon_project_staging
	)sub_worst
    where ranking < 2
)
select generation, `name`, label
from cte_pokemon
order by 1, 3;
 

select *
from pokemon_project_staging;


#labeling pokemons as fighter or defender based on their stats. if there is a tie, compare hp. if hp over median value then labled as brawler, if under labled as spell_caster

select `name`,
	case
		when att > def then 'Fighter'
        when def > att then 'Defender'
        else if(hp > (select (max(hp) + min(hp)) / 2 from pokemon_project_staging), 'Brawler', 'Spell_Caster')
	end as label
from(
		select `name`, hp,
			attack+sp_attack as att,
			defense+sp_defense as def
		from pokemon_project_staging
	)sub_pokemon;


#regular pokemons with higher rating than legendary pokemons average rating 


select `name`
from pokemon_project_staging
where legendary = 'False'
and total > (
				select avg(total)
                from pokemon_project_staging
                where legendary = 'True'
			);


#how many pokemons in each generation are legendary


select generation, count(legendary) count_legendary
from pokemon_project_staging
where legendary = 'True'
group by 1
order by 1;


      
select *
from pokemon_project_staging ;


#strongest version of pokemons who have multiple forms. if there is a tie, all pokemons sharing the same number are displayed

with cte_pokemon as
(
select *,
	dense_rank() over(partition by `number` order by total desc) as ranking
from pokemon_project_staging
where `number` in (
					select `number`
						from(
								select `number`, count(`number`)
								from pokemon_project_staging
								group by 1
								having count(`number`) > 1
							)sub_pokemons_with_multiple_forms
					)
)
select `number`, `name`
from cte_pokemon
where ranking < 2
;
      
      
drop table pokemon_project;

rename table pokemon_project_staging to pokemon_project;       


 
      
      
      
      
      
      
      
      
      
      
      
      
      
