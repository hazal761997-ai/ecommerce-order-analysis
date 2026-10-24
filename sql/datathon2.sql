SELECT *
FROM public.ecommerce_users

SELECT *
FROM public.ecommerce_products

SELECT *
FROM public.ecommerce_items

SELECT *
FROM public.ecommerce_orders


--duplicate kontrolü 0 satır ise duplicate değildir 


SELECT user_id,
	count(*) AS count 
FROM public.ecommerce_users
GROUP BY user_id
HAVING count(*) >1

SELECT product_id,
	count(*) AS count
FROM public.ecommerce_products
GROUP BY product_id 
HAVING count(*) >1

SELECT order_id,
	count(*) AS count
FROM public.ecommerce_items
GROUP BY order_id 
HAVING count(*) > 1

SELECT product_id ,
	count(*) AS count
FROM public.ecommerce_items
GROUP BY product_id 
HAVING count(*) > 1

SELECT order_id,
	   count(*) AS count
FROM public.ecommerce_orders
GROUP BY order_id 
HAVING count(*) > 1;

--tabloları birleştirme

SELECT *
FROM ecommerce_users AS u
JOIN ecommerce_orders AS o
 	ON u.user_id = o.user_id 
JOIN ecommerce_items AS i 
 	ON i.order_id = o.order_id 
JOIN ecommerce_products AS p 
ON p.product_id = i.product_id 


--3.2 Task 1 - Monthly Revenue by Category

SELECT category,
	EXTRACT(MONTH FROM o.order_date::DATE ) AS MONTH, --order_date varchar formatından date formatına çevirme 
	count(DISTINCT i.order_id) AS orders,
	sum(i.quantity) AS units_sold,
	sum(i.quantity * i.price)  AS revenue 
FROM ecommerce_users AS u
JOIN ecommerce_orders AS o
 	ON u.user_id = o.user_id 
JOIN ecommerce_items AS i 
 	ON i.order_id = o.order_id 
JOIN ecommerce_products AS p 
ON p.product_id = i.product_id 
GROUP BY category,EXTRACT(MONTH FROM o.order_date::DATE )
ORDER BY MONTH, revenue DESC

--3.3 Task 2 - Top Products

SELECT p.product_name,
	sum(i.quantity) AS units_sold,
	sum(i.quantity * i.price)  AS revenue 
FROM ecommerce_users AS u
JOIN ecommerce_orders AS o
 	ON u.user_id = o.user_id 
JOIN ecommerce_items AS i 
 	ON i.order_id = o.order_id 
JOIN ecommerce_products AS p 
ON p.product_id = i.product_id 
GROUP BY p.product_name
ORDER BY revenue DESC 
LIMIT 10 ;

---3.4 Task 3 - AOV by User Type 

SELECT u.user_type ,
	count(DISTINCT o.order_id) AS total_orders,
	sum(i.quantity * i.price)  AS total_revenue,
	sum(i.quantity * i.price)/count(DISTINCT o.order_id) AS average_order_value
FROM ecommerce_users AS u
JOIN ecommerce_orders AS o
 	ON u.user_id = o.user_id 
JOIN ecommerce_items AS i 
 	ON i.order_id = o.order_id 
JOIN ecommerce_products AS p 
ON p.product_id = i.product_id 
GROUP BY u.user_type 
ORDER BY average_order_value DESC 

--3.5 Task 4 - Customer Lifetime Value

SELECT o.user_id,
	count(DISTINCT o.order_id) AS total_orders,
	sum(i.quantity * i.price) AS lifetime_value,
	sum(i.quantity * i.price)/count(DISTINCT o.order_id) AS average_order_value,
	min(o.order_date ) AS first_order,
	max(o.order_date ) AS last_order
FROM ecommerce_users AS u
JOIN ecommerce_orders AS o
 	ON u.user_id = o.user_id 
JOIN ecommerce_items AS i 
 	ON i.order_id = o.order_id 
JOIN ecommerce_products AS p 
ON p.product_id = i.product_id 
GROUP BY o.user_id
ORDER BY lifetime_value DESC 


















