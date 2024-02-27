# Case_Study 1 - Danny's dinner
<p align="center">
<img src = https://8weeksqlchallenge.com/images/case-study-designs/1.png align="center" width="500" height="400">

----

## Table of content
* [Problem Statement]()
* [Entity Relationship diagram]()
* [Case Study Questions]()
* [Case Study Solutions]()

----
## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

----
#### Key Dataset
Danny has shared with you 3 key datasets for this case study:
* sales
* menu
* members

----
## Entity Relationship Diagram
<p align="center">
<img src = >

----
## ❓ Case Study Questions
1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
  not just sushi - how many points do customer A and B have at the end of January?

----
## 🗒️ Bonus Questions
* Join All The Things - Create a table that has these columns: customer_id, order_date, product_name, price, member (Y/N).
* Rank All The Things - Based on the table above, add one column: ranking.

----
## Case Study Solutions
To view code syntax [click here]()

### 1. What is the total amount each customer spent at the restaurant?
```TSQL
SELECT 
  s.customer_id, 
  SUM(price) AS total_amount
FROM sales s
JOIN menu USING (product_id)
GROUP BY s.customer_id;
```

| customer_id | total_amount |
|-------------|--------------|
| A           | 76 |
| B           | 74 |
| C           | 36 |

----
### 2. How many days has each customer visited the restaurant?
``` TSQL
SELECT
  customer_id,
  COUNT(DISTINCT(order_date)) AS number_of_visits
FROM sales
GROUP BY customer_id;
```
| customer_id    | number_of_visits |
|----------------|-----------------|
| A              | 4 |
| B              | 6 |
| C              | 2 |

----
### 3. What was the first item from the menu purchased by each customer?
```TSQL
SELECT
  DISTINCT(s.customer_id), m.product_name
FROM menu m
JOIN sales s USING (product_id)
WHERE s.order_date = ANY
(
  SELECT MIN(order_date) AS first_purchase 
  FROM sales
  GROUP BY customer_id
);
```
| customer_id  | product_name |
|--------------|--------------|
| A            | sushi |
| A            | curry |
| B            | curry |
| C            | ramen |

----
### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```TSQL
SELECT
  m.product_name,
  COUNT(m.product_name) AS number_of_purchase
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY number_of_purchase DESC
LIMIT 1 ;
```
| product_name  | number_of_purchase |
|---------------|--------------------|
| ramen             | 8 |

----
### 5. Which item was the most popular for each customer?
```TSQL
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
```
| customer_id  | popular_item | number_of_time_item_purchased |
|--------------|--------------|-------------------------------|
| A            | ramen |    3 |
| B            | curry |    2 |
| B            | sushi |    2 |
| B            | ramen |    2 |
| C            | ramen |    3 |

----
### 6. Which item was purchased first by the customer after they became a member?
```TSQL
WITH first_purchase_after_member AS 
(
	SELECT s.customer_id, s.order_date, m.product_name,
		   DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
	FROM sales s
	JOIN menu m ON s.product_id = m.product_id
	JOIN members mem ON mem.customer_id = s.customer_id
	WHERE s.order_date >= mem.join_date
)
SELECT * FROM first_purchase_after_member
WHERE rnk = 1;
```
| customer_id  | oreder_date | product_name | rnk |
|--------------|-------------|--------------|-----|
|  A  |  2021-01-07  |  curry  |  1  |
|  B  |  2021-01-11  |  sushi  |  1  |

----
### 7.Which item was purchased just before the customer became a member?
```TSQL
WITH last_purchase_before_member AS 
(
	SELECT s.customer_id, s.order_date, m.product_name,
		   DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
	FROM sales s
	JOIN menu m ON s.product_id = m.product_id
	JOIN members mem ON mem.customer_id = s.customer_id
	WHERE s.order_date < mem.join_date
)
SELECT * FROM last_purchase_before_member
WHERE rnk = 1;
```
| customer_id  | oreder_date | product_name | rnk |
|--------------|-------------|--------------|-----|
|  A  |  2021-01-01  |  sushi  |  1  |
|  A  |  2021-01-01  |  curry  |  1  |
|  B  |  2021-01-04  |  sushi  |  1  |

----
### 8.What is the total items and amount spent for each member before they became a member?
```TSQL
SELECT s.customer_id,
	   COUNT(m.product_name) AS total_item,
	   SUM(m.price) AS total_amount
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON mem.customer_id = s.customer_id
WHERE s.order_date <  mem.join_date
GROUP BY s.customer_id ;
```
| customer_id  | total_item | total_amount |
|--------------|-------------|--------------|
|  B  |  3  |  40  |
|  A  |  2  |  25  |

----
### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```TSQL
SELECT s.customer_id,
	SUM(CASE WHEN m.product_name = 'sushi' THEN m.price*20 ELSE m.price*10 END) AS total_points
FROM menu m
JOIN sales s ON m.product_id = s.product_id
GROUP BY s.customer_id;
```
| customer_id  | total_points |
|--------------|--------------|
| A            | 860 |
| B            | 940 |
| C            | 360 |

----
### 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```TSQL
SELECT s.customer_id,
  SUM(CASE WHEN s.order_date between mem.join_date AND DATE_ADD(mem.join_date, INTERVAL 7 DAY ) THEN m.price*20
           WHEN m.product_name='sushi' THEN m.price*20 ELSE m.price*10
      END ) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON mem.customer_id = s.customer_id
WHERE EXTRACT(MONTH FROM s.order_date)=1
GROUP BY s.customer_id;
```
| customer_id  | total_points |
|--------------|--------------|
| B            | 940  |
| A            | 1370 |

----
### Bonus Questions
### 1. Join All The Things - Create a table that has these columns: customer_id, order_date, product_name, price, member (Y/N).
```TSQL
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
	CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON mem.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date;
```    
| customer_id  | order_date | product_name | price | member |
|--------------|------------|--------------|-------|--------|
| A  | 2021-01-01 | sushi  | 10  | N  |
| A  | 2021-01-01 | curry  | 15  | N  |
| A  | 2021-01-07 | curry  | 15  | Y  |
| A  | 2021-01-10 | ramen  | 12  | Y  |
| A  | 2021-01-11 | ramen  | 12  | Y  |
| A  | 2021-01-11 | ramen  | 12  | Y  |
| B  | 2021-01-01 | curry  | 15  | N  |
| B  | 2021-01-02 | curry  | 15  | N  |
| B  | 2021-01-04 | sushi  | 10  | N  |
| B  | 2021-01-11 | sushi  | 10  | Y  |
| B  | 2021-01-16 | ramen  | 12  | Y  |
| B  | 2021-02-01 | ramen  | 12  | Y  |
| C  | 2021-01-01 | ramen  | 12  | N  |
| C  | 2021-01-01 | ramen  | 12  | N  |
| C  | 2021-01-07 | ramen  | 12  | N  |

----
### 2. Rank All The Things - Based on the table above, add one column: ranking.
```TSQL
WITH cte AS(
	SELECT s.customer_id, s.order_date, m.product_name, m.price, 
		   CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member
	FROM sales s
	LEFT JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mem ON mem.customer_id = s.customer_id
	ORDER BY s.customer_id, s.order_date
)
SELECT *, 
	CASE WHEN cte.member = 'N' THEN 'null' ELSE 
	DENSE_RANK() OVER(PARTITION BY cte.customer_id, cte.member ORDER BY cte.order_date) END rnk
FROM cte;
```
| customer_id  | order_date | product_name | price | member | rnk |
|--------------|------------|--------------|-------|--------|-----|
| A  | 2021-01-01 | sushi  | 10  | N  | null |
| A  | 2021-01-01 | curry  | 15  | N  | null |
| A  | 2021-01-07 | curry  | 15  | Y  | 1    |
| A  | 2021-01-10 | ramen  | 12  | Y  | 2    |
| A  | 2021-01-11 | ramen  | 12  | Y  | 3    |
| A  | 2021-01-11 | ramen  | 12  | Y  | 3    |
| B  | 2021-01-01 | curry  | 15  | N  | null |
| B  | 2021-01-02 | curry  | 15  | N  | null |
| B  | 2021-01-04 | sushi  | 10  | N  | null |
| B  | 2021-01-11 | sushi  | 10  | Y  | 1    |
| B  | 2021-01-16 | ramen  | 12  | Y  | 2    |
| B  | 2021-02-01 | ramen  | 12  | Y  | 3    |
| C  | 2021-01-01 | ramen  | 12  | N  | null |
| C  | 2021-01-01 | ramen  | 12  | N  | null |
| C  | 2021-01-07 | ramen  | 12  | N  | null |

----
