-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased? 

USE clique_bait;

create table Product_in as 
with cte as (
select
		e.visit_id,
        e.cookie_id,
		e.event_type,
		p.page_name,
		p.page_id,
		p.product_category,
        p.product_id
	from events e
	join page_hierarchy p on e.page_id = p.page_id),

cte2 as (
	select page_name,
    product_id,
    product_category,
	case when event_type = 1 then visit_id end as page_view,
	case when event_type = 2 then visit_id end as cart
	from cte 
	where product_id is not null
),

cte3 as (
select visit_id as purchased
from events
where event_type = 3
),
cte4 as(
select page_name, 
product_id,
product_category,
count(page_view) as product_viewed,
count(cart) as product_addedtocart,
count(purchased) as product_purchased,
count(cart) - count(purchased) as product_abadoned
from cte2
left join cte3 on purchased = cart
group by page_name, product_id, product_category)

select * from cte4;

SELECT * FROM product_in;

-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
create table Product_cat as 
with cte5 as (
select
		e.visit_id,
        e.cookie_id,
		e.event_type,
		p.page_name,
		p.page_id,
		p.product_category,
        p.product_id
	from events e
	join page_hierarchy p on e.page_id = p.page_id),

cte6 as (
select page_name,
    product_category,
	case when event_type = 1 then visit_id end as page_view,
	case when event_type = 2 then visit_id end as cart
	from cte5
	where product_id is not null
),

cte7 as (
select visit_id as purchased
from events
where event_type = 3
),
cte8 as(
select
product_category,
count(page_view) as product_viewed,
count(cart) as product_addedtocart,
count(purchased) as product_purchased,
count(cart) - count(purchased) as product_abadoned
from cte6
left join cte7 on purchased = cart
group by product_category)

select *
from cte8;

SELECT * FROM product_cat;




-- Use your 2 new output tables - answer the following questions:

-- Which product had the most views, cart adds and purchases?


SELECT
    page_name,
    product_viewed
FROM product_in
WHERE product_viewed = (
    SELECT MAX(product_viewed)
    FROM product_in
);


SELECT
    page_name,
    product_addedtocart
FROM product_in
WHERE product_addedtocart = (
    SELECT MAX(product_addedtocart)
    FROM product_in
);


SELECT
    page_name,
    product_purchased
FROM product_in
WHERE product_purchased = (
    SELECT MAX(product_purchased)
    FROM product_in
);

-- Which product was most likely to be abandoned?

SELECT
    page_name,
    product_abadoned
FROM product_in
WHERE product_abadoned = (
    SELECT max(product_abadoned)
    FROM product_in
);

-- Which product had the highest view to purchase percentage?

select page_name, round(100*(product_purchased/product_viewed), 2) as view_to_purchase
from product_in
order by 2 desc
limit 1;

-- What is the average conversion rate from view to cart add?
-- What is the average conversion rate from cart add to purchase?

SELECT 
  ROUND(100*AVG(product_addedtocart/product_viewed),2) AS avg_view_to_cart_add_conversion,
  ROUND(100*AVG(product_purchased/product_addedtocart),2) AS avg_cart_add_to_purchases_conversion_rate
FROM product_in
