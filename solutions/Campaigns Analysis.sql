use clique_bait;

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

SELECT 
    user_id,
    visit_id,
    MIN(e.event_time) AS visit_start_time,
    COUNT(CASE
        WHEN event_type = 1 THEN visit_id
    END) AS Page_views,
    COUNT(CASE
        WHEN event_type = 2 THEN visit_id
    END) AS Cart_adds,
    COUNT(CASE
        WHEN event_type = 3 THEN visit_id
    END) AS Purchase,
    CASE
        WHEN u.start_date BETWEEN ci.start_date AND ci.end_date THEN ci.campaign_name
    END AS Campaign_name,
    COUNT(CASE
        WHEN e.event_type = 4 THEN e.visit_id
    END) AS Impression,
    COUNT(CASE
        WHEN e.event_type = 5 THEN e.visit_id
    END) AS Click,
    GROUP_CONCAT(CASE
            WHEN
                event_type = 2
                    AND product_id IS NOT NULL
            THEN
                Page_name
            ELSE NULL
        END, 
        ", " ORDER BY e.sequence_number) AS cart_products
FROM
    users u
        JOIN
    events e ON u.cookie_id = e.cookie_id
        JOIN
    campaign_identifier ci ON e.event_time BETWEEN ci.start_date AND ci.end_date
        JOIN
    page_hierarchy ph ON ph.page_id = e.page_id
GROUP BY e.visit_id
ORDER BY user_id;
