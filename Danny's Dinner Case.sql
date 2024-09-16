
-- 														DANNY'S DINNER CASE STUDY - https://8weeksqlchallenge.com/case-study-1/

USE dannys_diner;

-- 1.0 - What is the total amount each customer spent at the restaurant?

select s.customer_id, SUM(price) AS 'Total_Spending'
from sales as s
inner join menu as m
on s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2.0 -  How many days has each customer visited the restaurant?

SELECT  customer_id, COUNT(DISTINCT(order_date)) AS Total_days_visited
FROM sales
GROUP BY customer_id;

-- 3.0 -  What was the first item from the menu purchased by each customer?

WITH combined_dataa AS (
	select s.customer_id, m.product_name,
    ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS row_num
	from sales as s
	join menu as m
	on s.product_id = m.product_id )
SELECT customer_id, product_name FROM combined_dataa
WHERE row_num = 1;

-- 4.0 - What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH cte AS ( SELECT COUNT(product_id) AS Frequency, product_id FROM sales GROUP BY product_id )
SELECT m.product_name, c.frequency
FROM menu as m
JOIN cte as c ON m.product_id = c.product_id
where c.frequency = (select max(frequency) from cte);

-- OR

SELECT m.product_name, COUNT(m.product_name) as Frequency
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(m.product_name) DESC
LIMIT 1; 

-- 5.0 -  Which item was the most popular for each customer?

WITH cte AS (
SELECT s.customer_id, m.product_name,
COUNT(*) as order_count,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) as rn
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)

SELECT customer_id, product_name FROM cte WHERE rn = 1;

-- 6.0 -  Which item was purchased first by the customer after they became a member?

WITH cte2 AS (
SELECT s.customer_id, s.order_date, s.product_id, me.join_date, m.product_name,
RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
FROM sales as s, members as me, menu as m
WHERE s.customer_id = me.customer_id AND s.product_id = m.product_id AND s.order_date > me.join_date
ORDER BY s.customer_id)

SELECT customer_id, product_name
FROM cte2
WHERE ranking = 1;

-- 7.0 - Which item was purchased just before the customer became a member?

WITH cte2 AS (
SELECT s.customer_id, s.order_date, s.product_id, me.join_date, m.product_name,
RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS ranking
FROM sales as s, members as me, menu as m
WHERE s.customer_id = me.customer_id AND s.product_id = m.product_id AND s.order_date < me.join_date
ORDER BY s.customer_id)

SELECT customer_id, product_name
FROM cte2
WHERE ranking = 1;

-- 8.0 - What is the total items and amount spent for each member before they became a member?

WITH cte AS (
SELECT s.customer_id, s.order_date, s.product_id, me.join_date, m.product_name, m.price,
RANK() OVER(PARTITION BY s.customer_id ORDER BY s.product_id ) AS rankk,
SUM(m.price) OVER (PARTITION BY s.customer_id) AS total_amount,
COUNT(s.customer_id) OVER (PARTITION BY s.customer_id) AS total_items
FROM sales as s, members as me, menu as m
WHERE s.customer_id = me.customer_id AND s.product_id = m.product_id AND s.order_date < me.join_date
ORDER BY s.customer_id)

SELECT customer_id, total_amount, total_items FROM cte
WHERE rankk = 1;

-- OR

SELECT s.customer_id,
COUNT(m.product_id) as total_items,
SUM(price) as total_amount
FROM menu as m
JOIN sales as s
ON m.product_id = s.product_id
JOIN members as mb
ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;

-- 9.0 -  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte AS (
SELECT s.customer_id, s.product_id, m.product_name, m.price, (CASE WHEN m.price > 10 THEN m.price*10 ELSE m.price*20 END) AS points
FROM sales as s, menu as m
WHERE s.product_id = m.product_id
ORDER BY s.customer_id)

SELECT customer_id, SUM(points) AS total_points
FROM cte
GROUP BY customer_id;

-- 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte AS (
SELECT s.customer_id, s.order_date, s.product_id, me.join_date, m.product_name, m.price, DATE_ADD(me.join_date, INTERVAL 7 DAY) as lucky_week,
(CASE WHEN s.order_date BETWEEN me.join_date AND DATE_ADD(me.join_date, INTERVAL 7 DAY) THEN m.price * 20 WHEN m.product_name = "sushi" THEN m.price * 20 ELSE m.price * 10 END) AS points
FROM sales as s, members as me, menu as m
WHERE s.customer_id = me.customer_id AND s.product_id = m.product_id
ORDER BY s.customer_id)

SELECT customer_id, SUM(points) AS total_points
FROM cte
GROUP BY customer_id;










