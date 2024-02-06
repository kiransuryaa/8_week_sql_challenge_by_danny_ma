-- QUESTIONS

-- 1) What is the total amount each customer spent at the restaurant?
-- 2) How many days has each customer visited the restaurant?
-- 3) What was the first item from the menu purchased by each customer?
-- 4) What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5) Which item was the most popular for each customer?
-- 6) Which item was purchased first by the customer after they became a member?
-- 7) Which item was purchased just before the customer became a member?
-- 8) What is the total items and amount spent for each member before they became a member?
-- 9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
--    - how many points would each customer have?
-- 10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi  - how many points do customer A and B have at the end of January?


-- 1) What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(price) AS total_amount
FROM sales s
JOIN menu USING (product_id)
GROUP BY s.customer_id;

-- 2) How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) AS number_of_visits
FROM sales
GROUP BY customer_id;

-- 3) What was the first item from the menu purchased by each customer?
SELECT DISTINCT(s.customer_id), m.product_name
FROM menu m
JOIN sales s USING (product_id)
WHERE s.order_date = ANY
(
	SELECT MIN(order_date) AS first_purchase 
	FROM sales
	GROUP BY customer_id
);

-- 4) What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(m.product_name) AS number_of_puchase
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY number_of_puchase DESC
LIMIT 1 ;

-- 5) Which item was the most popular for each customer?
WITH most_popular_item AS 
(
	SELECT s.customer_id, m.product_name, COUNT(m.product_name) AS number_of_time_item_purchased, 
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) AS rn
	FROM sales s
	JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
) 
SELECT mp.customer_id, mp.product_name AS Popular_item, mp.number_of_time_item_purchased
FROM most_popular_item mp
WHERE rn <= 1;

-- 6) Which item was purchased first by the customer after they became a member?
WITH first_purchase_after_member AS (
SELECT s.customer_id, s.order_date, m.product_name,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON mem.customer_id = s.customer_id
WHERE s.order_date >= mem.join_date
)
SELECT * FROM first_purchase_after_member
WHERE rnk = 1;

-- 7) Which item was purchased just before the customer became a member?
WITH last_purchase_before_member AS (
SELECT s.customer_id, s.order_date, m.product_name,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON mem.customer_id = s.customer_id
WHERE s.order_date < mem.join_date
)
SELECT * FROM last_purchase_before_member
WHERE rnk = 1;

-- 8) What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,
	COUNT(m.product_name) AS total_item,
	SUM(m.price) AS total_amount
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON mem.customer_id = s.customer_id
WHERE s.order_date <  mem.join_date
GROUP BY s.customer_id ;

-- 9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier-how many points would each customer have?    
SELECT s.customer_id,
       SUM(CASE WHEN m.product_name = 'sushi' THEN m.price*20 ELSE m.price*10 END) AS total_points
FROM menu m
JOIN sales s ON m.product_id = s.product_id
GROUP BY s.customer_id;

-- 10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi  - how many points do customer A and B have at the end of January?
SELECT s.customer_id,
	SUM(CASE
		WHEN s.order_date between mem.join_date AND DATE_ADD(mem.join_date, INTERVAL 7 DAY ) THEN m.price*20
        	WHEN m.product_name='sushi' THEN m.price*20 ELSE m.price*10 
	    END ) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON mem.customer_id = s.customer_id
WHERE EXTRACT(MONTH FROM s.order_date)=1
GROUP BY s.customer_id;

-- BONUS QUESTIONS

-- 11) Recreate the table output using available data
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
	CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON mem.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date;

-- 12) Rank all the things (Rank members & non- members to null)
WITH cte AS(
	SELECT s.customer_id, s.order_date, m.product_name, m.price, 
		   CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member
	FROM sales s
	LEFT JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mem ON mem.customer_id = s.customer_id
	ORDER BY s.customer_id, s.order_date
)
SELECT *,
	CASE WHEN cte.member = 'N' THEN 'null' ELSE DENSE_RANK() OVER(PARTITION BY cte.customer_id, cte.member ORDER BY cte.order_date) END rnk
FROM cte;

