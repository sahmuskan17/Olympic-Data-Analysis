CREATE TABLE OLYMPICS (
    ID INT,
    Name VARCHAR(500),
    Sex VARCHAR(50),
    Age VARCHAR(50),
    Height VARCHAR(50),
    Weight VARCHAR(50),
    Team VARCHAR(50),
    NOC VARCHAR(50),
    Games VARCHAR(50),
    Year INT,
    Season VARCHAR(50),
    City VARCHAR(50),
    Sport VARCHAR(50),
    Event VARCHAR(500),
    Medal VARCHAR(50)
);

CREATE TABLE NOC_OLYMPICS (
    NOC VARCHAR(50),
    region VARCHAR(50),
    notes VARCHAR(50)
);

SELECT * FROM OLYMPICS;
SELECT * FROM NOC_OLYMPICS;


-- List of all these 20 queries mentioned below:

-- 1)How many olympics games have been held?

SELECT COUNT(DISTINCT(GAMES)) AS NUM_olympics
FROM OLYMPICS;

-- 2)List down all Olympics games held so far.

SELECT DISTINCT(GAMES) AS Olympics_NAMES
FROM OLYMPICS;

-- 3)Mention the total no of nations who participated in each olympics game?

SELECT GAMES,COUNT(DISTINCT(NOC))  AS tOTAL_NATION
FROM OLYMPICS
GROUP BY GAMES ;

-- 4)Which year saw the highest and lowest no of countries participating in olympics?

with all_coutries as
 (select games, n.region
              from OLYMPICS o
              join NOC_OLYMPICS n ON n.noc=o.noc
              group by games, n.region),		  
 lowest_countries as 
  (select games,count(1) as count_country,'lowest' as rank 
   from all_coutries
   group by games
   order by count_country asc
   limit 1),
 higest_countries as 
  (select games,count(1) as count_country,'highest' as rank 
   from all_coutries
   group by games
   order by count_country desc
   limit 1)			  
select *
from lowest_countries 
union 
select *
from higest_countries;

-- 5)Which nation has participated in all of the olympic games?


select n.region as nation,count(distinct(o.games)) as total_games
from olympics as o
join noc_olympics as n on o.noc = n.noc
group by n.region
order by total_games desc;


-- 6)Identify the sport which was played in all summer olympics.

with t1 as(select count(distinct(games)) as total_games
		  from olympics
          where season = 'Summer' ),
	t2 as(select distinct(games) as all_games, sport
		  from olympics
          where season = 'Summer' ),
	t3 as(select sport, count(1) as no_of_count 
		  from t2
		  group by sport)
select *
from t3 join t1 on t1.total_games = t3.no_of_count;
		  
-- 7)Which Sports were just played only once in the olympics?

select sport,count(distinct(games))as total_games
from olympics 
group by sport 
having count(distinct(games))=1;

-- 8)Fetch the total no of sports played in each olympic games.

with 
   dis_games as( SELECT DISTINCT games, sport
                  FROM OLYMPICS),
   total_games as (select games, count(*) as total_no_sports
				  from dis_games
				  group by games)
select 	*	from total_games
order by total_no_sports desc;


-- 9)Fetch details of the oldest athletes to win a gold medal.

WITH temp AS (
    SELECT 
        name,
        CAST(CASE WHEN age = 'NA' THEN '0' ELSE age END AS INT) AS age,
        medal
    FROM 
        olympics
),
ranking AS (
    SELECT 
        *
    FROM 
        temp
    WHERE 
        medal = 'Gold'
	ORDER BY age DESC
)
SELECT 
    *
FROM 
    ranking
limit 2;


-- 10)Find the Ratio of male and female athletes participated in all olympic games.

with ratio as
             (select sex, count(1) as count_sex
			  from olympics
			  group by sex),
  ranking as 
            (select *, row_number() over(order by count_sex) as rnk
			 from ratio),
  min_count as
            (select count_sex 
			 from ranking
			 where rnk =1),
  max_count as
            (select count_sex 
			 from ranking
			 where rnk =2)
select concat('1:',round(max_count.count_sex ::decimal/min_count.count_sex ,2))	as ratios
from max_count,min_count;


-- 11)Fetch the top 5 athletes who have won the most gold medals

with athletes_gold_medal as
	(select name,team, count(medal) as medal_count
	from olympics
	where medal = 'Gold'
	group by name,team
	order by medal_count desc),
	
ranking as(select *,dense_rank() over(order by medal_count desc) as rnk
	       from athletes_gold_medal)
select *
from ranking
where rnk<=5;


--- 12)Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)

with athletes_gold_medal as
	(select name,team, count(medal) as medal_count
	from olympics
	where medal <>'NA'
	group by name,team
	order by medal_count desc),
	
ranking as(select *,dense_rank() over(order by medal_count desc) as rnk
	       from athletes_gold_medal)
select *
from ranking
where rnk<=5;

-- 13)Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won

select distinct n.region as country, count(o.medal) as total_medal
from olympics o
join  noc_olympics n on o.noc = n.noc
where medal <> 'NA'
group by country
order by total_medal desc
limit 5;

-- 14)List down total gold, silver and broze medals won by each country.

create extension tablefunc; -- import the extension for execute the crosstab query(change column into rows)

select country,
 coalesce(gold, 0) as gold,
 coalesce(silver,0) as silver,
 coalesce(bronze,0) as bronze
from crosstab(
	'select n.region as country, o.medal, count(1) as medal_count
	from olympics o
	join  noc_olympics n on o.noc = n.noc
	where medal <> ''NA''
	group by n.region,o.medal
	order by n.region,o.medal',
    'values (''Bronze''),(''Gold''),(''Silver'')')
as result(country varchar,gold bigint,silver bigint,bronze bigint)
order by gold desc, silver desc, bronze desc;


-- 15)List down total gold, silver and broze medals won by each country corresponding to each olympic games.

select  games,
 coalesce(gold, 0) as gold,
 coalesce(silver,0) as silver,
 coalesce(bronze,0) as bronze
from crosstab('select concat(games, '' - '', n.region) as games, medal, count(1) as total_medals
	from olympics o
	join  noc_olympics n on o.noc = n.noc
	where medal <> ''NA''
	group by n.region,medal,games
	order by games,medal', 
   'values (''Bronze''),(''Gold''),(''Silver'')')
as FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint);

-- 16)Identify which country won the most gold, most silver and most bronze medals in each olympic games.

with olympics_games as
	(select substring(country_games,1,position(' - 'in country_games) -1) as games,
	substring(country_games,position(' - ' in country_games) +3) as country,

	 coalesce(gold, 0) as gold,
	 coalesce(silver,0) as silver,
	 coalesce(bronze,0) as bronze
	from crosstab(
		'select concat(games ,'' - '', n.region)as country_games, medal, count(1) as medal_count
		from olympics o
		join  noc_olympics n on o.noc = n.noc
		where medal <> ''NA''
		group by n.region,medal,games
		order by n.region,medal,games',
		'values (''Gold''),(''Silver''),(''Bronze'')')
	as result(country_games varchar,gold bigint,silver bigint,bronze bigint))

select distinct games,
       concat(first_value(country) over(partition by games order by gold desc), '-'
			 ,first_value(gold) over(partition by games order by gold desc)) as max_gold,
		concat(first_value(country) over(partition by games order by silver desc), '-'
			 ,first_value(silver) over(partition by games order by silver desc)) as max_silver,
		concat(first_value(country) over(partition by games order by bronze desc), '-'
			 ,first_value(bronze) over(partition by games order by bronze desc)) as max_bronze	 
from olympics_games
order by games;


-- 17)Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with olympics_games as
	(select substring(country_games,1,position(' - 'in country_games) -1) as games,
	 substring(country_games,position(' - ' in country_games) +3) as country,
	 coalesce(gold, 0) as gold,
	 coalesce(silver,0) as silver,
	 coalesce(bronze,0) as bronze
	from crosstab(
		'select concat(games ,'' - '', n.region)as country_games, medal, count(1) as medal_count
		from olympics o
		join  noc_olympics n on o.noc = n.noc
		where medal <> ''NA''
		group by n.region,medal,games
		order by n.region,medal,games',
		'values (''Gold''),(''Silver''),(''Bronze'')')
	as result(country_games varchar,gold bigint,silver bigint,bronze bigint)),
total_medals as(SELECT games, n.region as country, count(1) as total_medal
		from olympics o
		join  noc_olympics n on o.noc = n.noc
		where medal <> 'NA'
    	GROUP BY games,n.region order by 1, 2 )	

select distinct og.games,
       concat(first_value(og.country) over(partition by og.games order by gold desc), '-'
			 ,first_value(og.gold) over(partition by og.games order by gold desc)) as max_gold,
		concat(first_value(og.country) over(partition by og.games order by silver desc), '-'
			 ,first_value(og.silver) over(partition by og.games order by silver desc)) as max_silver,
		concat(first_value(og.country) over(partition by og.games order by bronze desc), '-'
			 ,first_value(og.bronze) over(partition by og.games order by bronze desc)) as max_bronze,
		concat(first_value(tm.country) over(partition by tm.games order by total_medal desc ), '-'
			  ,first_value(tm.total_medal) over(partition by tm.games order by total_medal desc )) as	max_medal 
from olympics_games as og
join total_medals as tm on tm.games = og.games and tm.country =og.country
order by games;


-- 18)Which countries have never won gold medal but have won silver/bronze medals?	
	
with t1 as (
select games, region as country, medal
from olympics as o
join noc_olympics as n on n.noc = o.noc
where medal <> 'NA'
), t2 as (
select country,
sum(case when medal = 'Gold' then 1 else 0 end) as gold_medals,
sum(case when medal = 'Silver' then 1 else 0 end) as silver_medals,
sum(case when medal = 'Bronze' then 1 else 0 end) as bronze_medals
from t1
group by country
)
select * from t2
where gold_medals = 0;


-- 19) In which Sport/event, India has won highest medals.

select sport,count(medal) as total_wins
from olympics 
where team ='India' and medal <>'NA'
group by sport
order by total_wins desc
limit 1;


-- 20) Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

select team,sport,games,count(medal) as total_medal
from olympics
where team ='India' and medal <>'NA' and sport ='Hockey'
group by team, sport, games
order by total_medal desc;

