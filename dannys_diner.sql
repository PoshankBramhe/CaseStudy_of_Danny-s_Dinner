
CREATE DATABASE dannys_diner;

CREATE TABLE sales(
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu(
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members(
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

--Question 1 - What is the total amount each customer spent at the restaurant?

SELECT a.customer_id, SUM(b.price) as total_price
FROM sales a
INNER JOIN menu b
ON a.product_id = b.product_id
GROUP BY a.customer_id

--Question 2 - How many days has each customer visited the restaurant?

SELECT customer_id,COUNT(DISTINCT order_date) as total_visit
FROM sales
GROUP BY customer_id

--Question 3 - What was the first item from the menu purchased by each customer?

SELECT DISTINCT a.customer_id,b.product_name 
FROM sales a
INNER JOIN menu b
ON a.product_id = b.product_id
WHERE a.order_date = ANY (SELECT MIN(order_date) FROM sales GROUP BY customer_id)
--WHERE a.order_date IN (SELECT MIN(order_date) FROM sales GROUP BY customer_id)

--Question 4 - What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 b.product_name,COUNT(a.product_id) as purchased
FROM sales a
INNER JOIN menu b
ON a.product_id = b.product_id
GROUP BY b.product_name
ORDER BY purchased DESC

--Question 5 - Which item was the most popular for each customer?

WITH R as
(SELECT s.customer_id, m.product_name, count(s.product_id) as [count], 
dense_rank() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) as [rank]
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.customer_id,m.product_name,s.product_id)
SELECT customer_id, product_name, count , rank
FROM R
WHERE rank = 1

--Question 6 - Which item was purchased first by the customer after they became a member?

With rank as(
SELECT a.customer_id, m.product_name, dense_rank() OVER(PARTITION BY a.customer_id ORDER BY a.order_date) as r
FROM sales as a
INNER JOIN menu as m
ON a.product_id = m.product_id
INNER JOIN members as mem
ON mem.customer_id = a.customer_id
WHERE a.order_date > mem.join_date
)
SELECT customer_id, product_name
FROM rank
WHERE r = 1

--Question 7 - Which item was purchased just before the customer became a member?

WITH R as(
SELECT s.customer_id, m.product_name, dense_rank() OVER(PARTITION BY s.customer_id ORDER BY s.order_date desc) as r
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN  members as mem
ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
)
SELECT customer_id, product_name
FROM R
WHERE r = 1

--Question 8 - What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id,count(s.product_id) as total_items,sum(m.price) as total_amount
From sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN members as mem
ON s.customer_id = mem.customer_id
WHERE order_date < join_date
GROUP BY s.customer_id

--Question 9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH R as
(SELECT *,
CASE
WHEN m.product_name = 'sushi' THEN price * 20
WHEN m.product_name != 'sushi' THEN price * 10
END as points
FROM menu m)
SELECT customer_id, SUM(points) as points
FROM sales as s
INNER JOIN R as r
ON s.product_id = r.product_id
GROUP BY s.customer_id

--Question 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

SELECT customer_id, sum(Earning_Point) as Total_earning_point FROM
(SELECT s.customer_id,s.order_date,m.product_name,m.price,mm.join_date,
DATEADD(Day,7,mm.join_date) as Join_Week_Date,
EOMONTH('2021-01-01') as Last_Date,
CASE
--Before join program
    WHEN order_date >='2021-01-01' AND order_date < join_date AND m.product_name = 'Sushi' Then m.price * 20
    WHEN order_date >='2021-01-01' AND order_date < join_date Then m.price * 10
--After join till week
    When order_date >= join_date AND order_date < DATEADD(Day,7,mm.join_date) Then m.price*20
--After join till week till end
    When order_date > DATEADD(Day,7,mm.join_date) AND order_date <= EOMONTH('2021-01-01') AND m.product_name = 'Sushi' Then m.price * 20
    When order_date > DATEADD(Day,7,mm.join_date) AND order_date <= EOMONTH('2021-01-01') Then m.price * 10
END as Earning_Point
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN members as mm
ON mm.customer_id = s.customer_id) A
GROUP BY customer_id

                                                                   /*END*/