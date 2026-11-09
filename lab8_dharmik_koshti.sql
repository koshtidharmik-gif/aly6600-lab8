-- Task 1: Single CTE
-- Customers whose total spending is above the average customer's total.
-- ---------------------------------------------------------------------
WITH customer_spend AS (
  -- Step 1: total spend per customer
  SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_spend
  FROM `sakila-aly6600.sakila.customer` AS c
  JOIN `sakila-aly6600.sakila.payment`  AS p
    ON c.customer_id = p.customer_id
  GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
  customer_id,
  first_name,
  last_name,
  ROUND(total_spend, 2) AS total_spend
FROM customer_spend
WHERE total_spend > (SELECT AVG(total_spend) FROM customer_spend)
ORDER BY total_spend DESC;
 
 
-- ---------------------------------------------------------------------
-- Task 2: Chained CTEs
-- Top 5 cities by number of above-average-spending customers,
-- with each city's total revenue from those customers.
-- ---------------------------------------------------------------------
WITH customer_spend AS (
  -- CTE 1: total spend per customer (keep address_id for the city join)
  SELECT
    c.customer_id,
    c.address_id,
    SUM(p.amount) AS total_spend
  FROM `sakila-aly6600.sakila.customer` AS c
  JOIN `sakila-aly6600.sakila.payment`  AS p
    ON c.customer_id = p.customer_id
  GROUP BY c.customer_id, c.address_id
),
above_avg_customers AS (
  -- CTE 2: keep only customers above the average total spend
  SELECT customer_id, address_id, total_spend
  FROM customer_spend
  WHERE total_spend > (SELECT AVG(total_spend) FROM customer_spend)
),
customer_city AS (
  -- CTE 3: join through address to city
  SELECT
    a.customer_id,
    ci.city,
    a.total_spend
  FROM above_avg_customers AS a
  JOIN `sakila-aly6600.sakila.address` AS ad
    ON a.address_id = ad.address_id
  JOIN `sakila-aly6600.sakila.city` AS ci
    ON ad.city_id = ci.city_id
)
-- Final SELECT: aggregate by city, rank, keep top 5
-- Ties use RANK(), so equal revenue shares a rank (e.g. 1, 2, 3, 4, 4).
SELECT
  city,
  COUNT(customer_id)        AS above_avg_customers,
  ROUND(SUM(total_spend), 2) AS total_revenue,
  RANK() OVER (ORDER BY COUNT(customer_id) DESC, SUM(total_spend) DESC) AS city_rank
FROM customer_city
GROUP BY city
ORDER BY city_rank, city   -- city breaks ties so the order is stable
LIMIT 5;
