USE clique_bait;

-- How many users are there?--

SELECT COUNT(DISTINCT user_id) as Total_users FROM users;

-- How many cookies does each user have on average?
With cookie as(
select user_id, count(cookie_id) as count_of_cookie
from users
group by user_id)

select round(avg(count_of_cookie),0) as average_cookie from cookie;


-- What is the unique number of visits by all users per month?

SELECT 
  EXTRACT(MONTH FROM event_time) as month, 
  COUNT(DISTINCT visit_id) AS unique_visit_count
FROM clique_bait.events
GROUP BY EXTRACT(MONTH FROM event_time);


-- What is the number of events for each event type?

SELECT 
    e.event_type AS unique_type,
    COUNT(*) AS event_count,
    i.event_name
FROM
    events e
        JOIN
    event_identifier i ON e.event_type = i.event_type
GROUP BY event_name;

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));  -- this enables us to group with nonagreggated colums--


-- What is the percentage of visits which have a purchase event?

select 
	round((select count(distinct visit_id) from events where event_type = 3) *100 / count(distinct visit_id))
    as purchase_percent
from events;

-- What is the percentage of visits which view the checkout page but do not have a purchase event?
with cte as(
select e.*,
i.event_name,
p.page_name,
p.product_id,
case when p.page_name like '%Checkout%' then e.visit_id end as viewed_checkout,
case when p.page_name like '%Confirmation%' then e.visit_id end as purchase
from events e
join event_identifier i on e.event_type = i.event_type
join page_hierarchy p on e.page_id = p.page_id

)
select 
count(viewed_checkout) as total_viewed_checkout,
count(purchase) as total_purchased, 
round(100 *(count(viewed_checkout) - count(purchase))/count(viewed_checkout), 2) as percentage
from cte;


-- What are the top 3 pages by number of views?
with cte as (
select
p.page_name,
count(e.visit_id) as num_of_visit
from events e
join page_hierarchy p on e.page_id = p.page_id
group by p.page_name),

cte2 as(
select page_name,
num_of_visit,
rank() over(order by num_of_visit desc) as rnk
from cte)

select page_name,
num_of_visit
from cte2
where rnk <= 3;



-- What is the number of views and cart adds for each product category?

select
p.product_category,
count(case when i.event_name like '%view%' then e.visit_id end) as views,
count(case when i.event_name like '%add%' then e.visit_id end) as added_to_cart
from events e 
join page_hierarchy p on e.page_id = p.page_id
join event_identifier i on e.event_type = i.event_type
where
p.product_category is not null
group by 1
order by views desc;

-- What are the top 3 products by purchases?
WITH cte AS (
  SELECT DISTINCT visit_id AS purchase_id
  FROM events 
  WHERE event_type = 3
),
cte2 AS (
  SELECT 
    p.page_name,
    p.page_id,
    e.visit_id 
  FROM events e
  LEFT JOIN page_hierarchy p ON p.page_id = e.page_id
  WHERE p.product_id IS NOT NULL 
    AND e.event_type = 2
)
SELECT 
  page_name as Product,
  COUNT(*) AS Quantity_purchased
FROM cte 
LEFT JOIN cte2 ON visit_id = purchase_id 
GROUP BY page_name
ORDER BY COUNT(*) DESC 
LIMIT 3;

