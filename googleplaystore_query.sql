select *
from google_stuff a
join google_reviews b
on a.app = b.app

---------------------------------------------
select distinct category, avg(rating) over(partition by category)
from google_stuff a
join google_reviews b
on a.app = b.app
where rating != 0
group by 1, a.rating
order by 2 desc
limit 100

-- partition by category, querying for avg rating, order by rating desc
----------------------------------------------

select (sub.type_free / sub.total_type::float) * 100 as perc_of_free_apps,
	   (sub.type_paid / sub.total_type::float) * 100 as perc_of_paid_apps,
	   sub.type_free, 
	   sub.type_paid
from(
	select count(type_) as total_type,
		   sum(case when type_ = 'Free' then 1 else 0 end) as type_free,
		   sum(case when type_ = 'Paid' then 1 else 0 end) as type_paid
	from google_stuff
	) as sub

-- percentage of free vs paid applications
----------------------------------------------
-- select distinct a.app, count(sentiment_polarity) as total_polarity_greater_than_half
-- from google_stuff a
-- join google_reviews b
-- on a.app = b.app
-- where sentiment_polarity >= 0.5
-- group by 1
-- order by 2 desc
----------------------------------------------
-- select distinct category, count(category) as category_count
-- from google_stuff
-- where type_ = 'Free'
-- group by 1
-- order by 2 desc

-- select distinct category, count(category) as category_count
-- from google_stuff
-- where type_ = 'Paid'
-- group by 1
-- order by 2 desc
-----------------------------------------------
select sub.category,
	   (sub.type_free / sub.total_type::float) * 100 as perc_of_free_apps,
	   (sub.type_paid / sub.total_type::float) * 100 as perc_of_paid_apps,
	   sub.type_free, 
	   sub.type_paid
from(
	select category, 
		   count(type_) as total_type,
		   sum(case when type_ = 'Free' then 1 else 0 end) as type_free,
		   sum(case when type_ = 'Paid' then 1 else 0 end) as type_paid
	from google_stuff
	group by 1
	) as sub
group by sub.category, sub.type_free, sub.type_paid, sub.total_type
order by sub.total_type desc
-- percentages of free vs paid apps based on categories
-- we find that family apps are very large player within the app categories
-- What genre in the family category gets has a larger set of apps?
-----------------------------------------------
-- we know that free games are a majority within the google store, but why?
-- what if we wanted to start out on the google store, yet there is very high interest
-- for that specific category, what category and genre should an upcoming app developer
-- set foot into?
-----------------------------------------------
select sub.category,sub.genres,
	   (sub.type_free / sub.total_type::float) * 100 as perc_of_free_apps,
	   (sub.type_paid / sub.total_type::float) * 100 as perc_of_paid_apps,
	   sub.type_free, 
	   sub.type_paid,
	   sub.total_type
from(
	select category, 
		   genres,
		   count(type_) as total_type,
		   sum(case when type_ = 'Free' then 1 else 0 end) as type_free,
		   sum(case when type_ = 'Paid' then 1 else 0 end) as type_paid
	from google_stuff
	group by 1, 2
	) as sub
where sub.category = 'GAME'
group by sub.category, sub.genres, sub.type_free, sub.type_paid, sub.total_type
order by sub.total_type desc
-- Entertainment and Education are the top 2 family-oriented apps within the google store
------------------------------------------------

select app, category, reviews, rating, installs
from google_stuff 
where installs = (select max(installs)
				  from google_stuff)
order by 3 desc, 5 desc
-- top 20 most popular apps w/ respect to reviews, ratings, and total installs
-- facebook stands at the top of the most downloaded app in the google store
--------------------------------------------------

-- okay this is what I see, the main thing is before the where, which is 
select distinct category, genres, max(reviews) as max_reviews, max(installs) as max_installs
from google_stuff
group by 1,2
order by 4 desc, 3 desc
-- we see that social is a very popular category, tons reviews and installs
-- communication comes second, third gaming
-- ----------------------------------------------------

select distinct category, genres, sum(reviews) as sum_reviews, avg(rating) as avg_rating, sum(installs) as sum_installs
from google_stuff
where category = 'GAME'
AND rating != 0
group by 1,2
order by 5 desc, 4 desc
-- if we wanted to build a mobile game, the best genre to go into is arcade, with a max install
-- of 1 billion+ , and the worst is where the genre is music
-- looking over our query, we can see that strategy games have the better ratings
-- we use sum because theres multiple of apps and that fits with our category and genre case
-- (we are not looking at a individual app), use sum to aggregate multiple apps of that genre
select count(*)
from (	select app, category, genres, installs, rating
		from google_stuff
		where category = 'GAME'
		AND rating BETWEEN 4 AND 5
		AND rating != 0
		group by 1,2,3,4,5
	  	order by 5 desc, 4 desc
	 ) as sub
-- there are 763 arcade games that are above and equal to 4 and 5 stars

select count(*)
from (	select app, category, genres, installs, rating
		from google_stuff
		where category = 'GAME'
		group by 1,2,3,4,5
	  	order by 5 desc, 4 desc
	 ) as sub
-- there are 959 games above zero rating


select count(*)
from (	select app, category, genres, installs, rating
		from google_stuff
		where category = 'GAME'
	  	AND rating = 0
		group by 1,2,3,4,5
	  	order by 5 desc, 4 desc
	 ) as sub
-- there are 47 games with no ratings

select app, category, genres, installs, reviews, rating
from google_stuff
where category = 'GAME'
AND rating = 0
order by 4 desc, 5 desc
-- we can see a problem here, there can be no possible reason for an app to have 100,000 installs
-- without having a rating, could possibly be a bug in the system or human error
-- reviews look healthy for the amount of installs for the app 'Adivina el Emoji', has to have at
-- least a 1 rating because google play store requires you to review and rate only once per user/install
---------------------------------------------------
select app, (reviews / installs::float) as reviews_per_install,
	   reviews,
	   installs
from google_stuff
where reviews != 0
AND installs != 0
AND category = 'GAME'
order by 2 desc
-- Possibly for some of these games, users could have reviewed and uninstalled the application, resulting in the
-- 'Active Install' count to decrease
-- Installs is a running total (Active Installs)
---------------------------------------------------
select b.app, sub.category, (b.installs / sub.total_sum) * 100 as perc_install_category
from (select distinct category, sum(installs) as total_sum
from google_stuff
where installs != 0
group by 1) as sub
join google_stuff as b
on sub.category = b.category
order by 2, 3 desc
-- (specific app # of install / its category of total install)
-- finding the "percentage" of a specific app's total install vs total categorical install
--------------------------------------------------