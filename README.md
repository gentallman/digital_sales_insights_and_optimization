<h1 align="center"> E-commerce Sales Performance Analysis </h1>
<br>
<p align="center">
  <img src="https://github.com/user-attachments/assets/2edc6b97-01b3-4e95-9cee-36fb8dfee025" width="230">
</p>


## **Project Overview**

I analyzed a dataset of over 20,000 sales records from an Amazon-like e-commerce platform, focusing on customer behavior, product performance, and sales trends using PostgreSQL. The project included querying data to uncover insights into revenue generation, identifying key customer segments, and managing inventory based on demand trends. This involved solving business challenges like tracking seasonal sales patterns, optimizing inventory restocking strategies, and identifying high-value customers.

A major part of the work was dedicated to cleaning the dataset by handling missing values, ensuring data integrity, and developing structured queries to address business problems in real-world scenarios, similar to the challenges faced by Indian e-commerce platforms like Flipkart or BigBasket. 

The ERD diagram created for this project visually represents the database schema, highlighting relationships between key tables such as customers, products, and transactions.

![amazon_db (1)](https://github.com/user-attachments/assets/16531b16-e104-42b3-bb87-b4ff4ff4a4fd)


## **Database Setup & Design**

### **Schema Structure**

```sql
--- Schema Structure

--- Parent Table Creation :

-- Category 

CREATE TABLE category (
	category_id INT PRIMARY KEY,
	category_name VARCHAR(20)
);

-- Customers 

CREATE TABLE customers (
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	state VARCHAR(20),
	address VARCHAR(5) DEFAULT ('xxxx')
);

-- Sellers

CREATE TABLE sellers(
	seller_id INT PRIMARY KEY,
	seller_name VARCHAR(25),
	origin VARCHAR(10)
);

-- Updating datatype of Sellers table

ALTER TABLE sellers
	ALTER COLUMN origin TYPE VARCHAR(10);

--- Child Table Creation :

-- Product

CREATE TABLE products (
	product_id INT PRIMARY KEY,
	product_name VARCHAR(50),
	price FLOAT,
	cogs FLOAT,
	category_id INT, --FK
	CONSTRAINT products_fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

-- orders

CREATE TABLE orders(
	order_id INT PRIMARY KEY,
	order_date DATE,
	customer_id INT, --FK
	seller_id INT, --FK
	order_status VARCHAR(15),
	CONSTRAINT orders_fk_customers FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
	CONSTRAINT orders_fk_seller FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);

-- order_items

CREATE TABLE order_items(
	order_item_id INT PRIMARY KEY,
	order_id INT, --FK
	product_id INT, --FK
	quantity INT,
	price_per_unit FLOAT,
	CONSTRAINT order_items_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id),
	CONSTRAINT order_items_fk_products FOREIGN KEY(product_id) REFERENCES products(product_id)	
);

-- payments

CREATE TABLE payments(
	payment_id INT PRIMARY KEY,
	order_id INT, --FK
	payment_date DATE,
	payment_status VARCHAR(20),
	CONSTRAINT payments_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- shipping

CREATE TABLE shipping(
	shipping_id	INT PRIMARY KEY,
	order_id INT, -- FK
	shipping_date DATE,
	return_date DATE,
	shipping_providers VARCHAR(15),
	delivery_status VARCHAR(15),
	CONSTRAINT shipping_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- inventory
	
CREATE TABLE inventory(
	inventory_id INT,
	product_id INT, --FK
	stock INT,
	warehouse_id INT,
	last_stock_date DATE,
	CONSTRAINT inventory_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

---

## **Task: Data Cleaning**

I cleaned the dataset by:
- **Removing duplicates**: Duplicates in the customer and order tables were identified and removed.
- **Handling missing values**: Null values in critical fields (e.g., customer address, payment status) were either filled with default values or handled using appropriate methods.

---

## **Handling Null Values**

Null values were handled based on their context:
- **Customer addresses**: Missing addresses were assigned default placeholder values.
- **Payment statuses**: Orders with null payment statuses were categorized as “Pending.”
- **Shipping information**: Null return dates were left as is, as not all shipments are returned.

---

## **Objective**

The primary objective of this project is to showcase SQL proficiency through complex queries that address real-world e-commerce business challenges. The analysis covers various aspects of e-commerce operations, including:
- Customer behavior
- Sales trends
- Inventory management
- Payment and shipping analysis
- Forecasting and product performance
  

## **Identifying Business Problems**

Key business problems identified:
1. Low product availability due to inconsistent restocking.
2. High return rates for specific product categories.
3. Significant delays in shipments and inconsistencies in delivery times.
4. High customer acquisition costs with a low customer retention rate.

---

## **Solving Business Problems**

### Solutions Implemented:
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.

```sql
--  Altering table by adding new column

ALTER TABLE order_items
ADD COLUMN total_sales FLOAT;

-- Updating column with values (quantity * price_per_unit)

UPDATE order_items
SET total_sales = quantity * price_per_unit;

SELECT 
	oi.product_id as "Product_ID", 
	p.product_name as "Product", 
	ROUND(SUM(oi.total_sales)::numeric, 2) AS "Total Sales",
	COUNT(o.order_id) AS "Total Orders"
FROM 
	order_items AS oi
JOIN
	orders AS o
ON 
	oi.order_id = o.order_id
JOIN
	products AS p
ON 
	oi.product_id = p.product_id
GROUP BY 
	oi.product_id, p.product_name
ORDER BY 
	"Total Sales" DESC
LIMIT 10;
```

2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.

```sql
SELECT 
    c.category_id AS "Category_ID",
    c.category_name AS "Category",
    ROUND(SUM(oi.total_sales)::numeric,2) AS "Total Sales",
    ROUND((SUM(oi.total_sales) / (SELECT SUM(total_sales) FROM order_items) * 100)::numeric, 2) AS "Total Contribution (%)"
FROM
    order_items AS oi
JOIN 
    products AS p
ON	
    oi.product_id = p.product_id
LEFT JOIN
    category AS c
ON
    p.category_id = c.category_id
GROUP BY 
    c.category_id, c.category_name
ORDER BY
    "Total Sales" DESC;
```

3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.

```sql
SELECT
    c.customer_id as "Customer_ID",
    CONCAT(c.first_name, ' ', c.last_name) AS "Name",
	COUNT(o.order_id) AS "Orders",
    ROUND((SUM(oi.total_sales) / COUNT(o.order_id))::numeric,2) AS "AOV"
FROM 
    customers AS c
JOIN 
    orders AS o
ON 
    c.customer_id = o.customer_id
JOIN 
    order_items AS oi
ON 
    o.order_id = oi.order_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name
HAVING 
    COUNT(o.order_id) > 5
ORDER BY 
    "AOV" DESC;
```

4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!

```sql
SELECT
    "Year",
    "Month",
    "Total Sales" AS "Current Month Sale",
    LAG("Total Sales", 1) OVER (ORDER BY "Year", "Month") AS "Last Month Sale"
FROM
(
    SELECT 
        EXTRACT(MONTH FROM o.order_date) AS "Month",
        EXTRACT(YEAR FROM o.order_date) AS "Year",
        ROUND(SUM(oi.total_sales)::NUMERIC, 2) AS "Total Sales"
    FROM 
        orders o
    JOIN
        order_items oi
    ON
        oi.order_id = o.order_id
    WHERE
        o.order_date >= CURRENT_DATE - INTERVAL '1 year' -- Get data from the last year
    GROUP BY 
        "Year", "Month"
    ORDER BY 
        "Year", "Month"
) AS "Sales Summary";
```


5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.

```sql
-- Approach 1: Using a subquery to exclude customers with orders
SELECT * 
FROM 
    customers
WHERE 
    customer_id NOT IN (
        SELECT DISTINCT customer_id 
        FROM orders
    );
```
```sql
-- Approach 2: Using a LEFT JOIN to find customers without orders
SELECT * 
FROM
    customers AS c
LEFT JOIN
    orders AS o
ON
    o.customer_id = c.customer_id
WHERE 
    o.order_date IS NULL;
```

6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.

```sql
WITH Ranking_Table AS (
    SELECT  
        c.state AS "State", 
        ct.category_name AS "Category", 
        ROUND(SUM(oi.total_sales)::NUMERIC, 2) AS "Total Sales",
        RANK() OVER (PARTITION BY c.state ORDER BY ROUND(SUM(oi.total_sales)::NUMERIC, 2) ASC) AS "Rank"
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN	
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN	
        category ct ON p.category_id = ct.category_id
    GROUP BY
        c.state, ct.category_name
)

SELECT "State", "Category", "Total Sales" 
FROM Ranking_Table 
WHERE "Rank" = 1;
```

7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.

```sql
SELECT
    c.customer_id AS "Customer_ID",
    CONCAT(c.first_name, ' ', c.last_name) AS "Name",
    ROUND(SUM(oi.total_sales)::NUMERIC, 2) AS "CLTV",
    DENSE_RANK() OVER (ORDER BY ROUND(SUM(oi.total_sales)::NUMERIC, 2) DESC) AS "Rank"
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_id, c.first_name, c.last_name;
```

8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.

```sql
SELECT 
	i.inventory_id AS "Inventory ID",
	p.product_name AS "Product",
	i.stock AS "Current Stock Left",
	i.last_stock_date AS "Last Stock Date",
	i.warehouse_id AS "Warehouse ID"
FROM 
    inventory i
JOIN 
    products p ON i.product_id = p.product_id
WHERE 
    i.stock < 10
ORDER BY 
    i.stock DESC;
```

9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.

```sql
SELECT 
    c.*,
    o.*,
    sh.shipping_providers,
    sh.shipping_date - o.order_date AS "Delivery Days"
FROM 
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN 
    shipping sh ON o.order_id = sh.order_id
WHERE 
    sh.shipping_date - o.order_date > 3;
```

10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).

```sql
SELECT 
    p.payment_status AS "Payment Status",
    COUNT(*) AS "Count",
    ROUND((COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM payments)::NUMERIC) * 100, 2) AS "Breakdown (%)"
FROM 
    orders o
JOIN 
    payments p ON o.order_id = p.order_id
GROUP BY 
    p.payment_status;
```

11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.

```sql
WITH top_sellers AS 
(
    SELECT 
        s.seller_id,
        s.seller_name,
        ROUND(SUM(oi.total_sales)::numeric,2) AS "Total Sales"
    FROM 
        orders AS o
    JOIN 
        sellers AS s ON o.seller_id = s.seller_id
    JOIN 
        order_items AS oi ON oi.order_id = o.order_id
    GROUP BY 
        s.seller_id, s.seller_name
    ORDER BY 
        "Total Sales" DESC
    LIMIT 5
),
seller_order_status AS 
(
    SELECT
        o.seller_id,
        ts.seller_name,
        o.order_status,
        COUNT(*) AS "Total Orders"
    FROM 
        orders AS o
    JOIN 
        top_sellers AS ts ON ts.seller_id = o.seller_id
    WHERE 
        o.order_status NOT IN ('Inprogress', 'Returned')
    GROUP BY 
        o.seller_id, o.order_status, ts.seller_name
)

SELECT
    seller_id as "Seller ID",
    seller_name as "Name",
    SUM(CASE WHEN order_status = 'Completed' THEN "Total Orders" ELSE 0 END) AS "Completed Orders",
    SUM(CASE WHEN order_status = 'Cancelled' THEN "Total Orders" ELSE 0 END) AS "Cancelled Orders",
    SUM("Total Orders") AS "Total Orders",
    ROUND(SUM(CASE WHEN order_status = 'Completed' THEN "Total Orders" ELSE 0 END)::NUMERIC / 
          NULLIF(SUM("Total Orders")::NUMERIC, 0) * 100, 2) AS "Order Completion Rate"
FROM 
    seller_order_status
GROUP BY 
    "Seller ID", "Name"
ORDER BY 
    "Seller ID", "Name";
```

12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/

```sql
SELECT 
    product_id,
    product_name,
    "Profit Margin",
    DENSE_RANK() OVER(ORDER BY "Profit Margin" DESC) AS "Product Rank"
FROM
(
    SELECT
        p.product_id,
        p.product_name,
        ROUND((SUM(oi.total_sales - (p.cogs * oi.quantity)) / NULLIF(SUM(oi.total_sales), 0))::numeric * 100, 2) AS "Profit Margin"
    FROM 
        products AS p
    JOIN 
        order_items AS oi ON p.product_id = oi.product_id
    GROUP BY 
        p.product_id, 
        p.product_name
) AS subquery;
```

13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.

```sql
SELECT 
    p.product_id,
    p.product_name,
    COUNT(*) AS "Total Units Sold",
    SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS "Total Returned",
    ROUND((SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric / COUNT(*)::numeric * 100), 2) AS "Returned (%)"
FROM 
    order_items AS oi
JOIN 
    products AS p ON oi.product_id = p.product_id
JOIN 
    orders AS o ON o.order_id = oi.order_id
GROUP BY 
    p.product_id,
    p.product_name
ORDER BY 
    "Returned (%)" DESC
LIMIT 10;
```

14. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.

```sql
SELECT
    c.customer_id AS "Customer ID",
	o.order_id AS "Order ID",
    CONCAT(c.first_name, ' ', c.last_name) AS "Name",
    c.state AS "State",
    o.order_date AS "Order Date",
    o.order_status AS "Order Status"
FROM 
    customers AS c
JOIN 
    orders AS o ON c.customer_id = o.customer_id
JOIN 
    payments AS p ON o.order_id = p.order_id
WHERE 
    o.order_status = 'Inprogress' 
    AND p.payment_status = 'Payment Successed';
```

15. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns

```sql
WITH seller_not_sale_6_month AS (
    -- Sellers who have not made any sales in the last 6 months
    SELECT seller_id, seller_name
    FROM sellers
    WHERE seller_id NOT IN (
        SELECT DISTINCT seller_id 
        FROM orders 
        WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
    )
)

SELECT 
    s.seller_id "Seller ID",
	s.seller_name as "Name",
    MAX(o.order_date) AS "Last Sale Date",
    COALESCE(SUM(oi.total_sales), 0) AS "Total Sales" 
FROM 
    seller_not_sale_6_month AS s
LEFT JOIN 
    orders AS o ON s.seller_id = o.seller_id
LEFT JOIN 
    order_items AS oi ON o.order_id = oi.order_id
GROUP BY 
    "Seller ID", "Name";
```

16. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
```sql
SELECT
	"Name",
	"Total Orders",
	"Total Returns",
	CASE 
		WHEN "Total Returns" > 5 THEN 'Returning' 
		ELSE 'New' 
	END AS "Category"
FROM (
	SELECT
		CONCAT(c.first_name, ' ', c.last_name) AS "Name",
		COUNT(o.order_id) AS "Total Orders",
		SUM(CASE 
			WHEN o.order_status = 'Returned' THEN 1 
			ELSE 0  
		END) AS "Total Returns"
	FROM 
		customers AS c
	JOIN 
		orders AS o ON o.customer_id = c.customer_id
	GROUP BY 
		c.first_name, c.last_name
) AS subquery
ORDER BY  
	"Total Returns" DESC;
```

17. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.

```sql
SELECT 
	s.shipping_providers,
	COUNT(o.order_id) as order_handled,
	SUM(oi.total_sale) as total_sale,
	COALESCE(AVG(s.return_date - s.shipping_date), 0) as average_days
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
shippings as s
ON 
s.order_id = o.order_id
GROUP BY 1
```

18. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result
Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)

```sql
WITH last_year_sale
as
(
SELECT 
	p.product_id,
	p.product_name,
	SUM(oi.total_sale) as revenue
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2022
GROUP BY 1, 2
),

current_year_sale
AS
(
SELECT 
	p.product_id,
	p.product_name,
	SUM(oi.total_sale) as revenue
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1, 2
)

SELECT
	cs.product_id,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	ls.revenue - cs.revenue as rev_diff,
	ROUND((cs.revenue - ls.revenue)::numeric/ls.revenue::numeric * 100, 2) as reveneue_dec_ratio
FROM last_year_sale as ls
JOIN
current_year_sale as cs
ON ls.product_id = cs.product_id
WHERE 
	ls.revenue > cs.revenue
ORDER BY 5 DESC
LIMIT 10
```


19. Final Task: Stored Procedure
Create a stored procedure that, when a product is sold, performs the following actions:
Inserts a new sales record into the orders and order_items tables.
Updates the inventory table to reduce the stock based on the product and quantity purchased.
The procedure should ensure that the stock is adjusted immediately after recording the sale.

```SQL
CREATE OR REPLACE PROCEDURE add_sales
(
p_order_id INT,
p_customer_id INT,
p_seller_id INT,
p_order_item_id INT,
p_product_id INT,
p_quantity INT
)
LANGUAGE plpgsql
AS $$

DECLARE 
-- all variable
v_count INT;
v_price FLOAT;
v_product VARCHAR(50);

BEGIN
-- Fetching product name and price based p id entered
	SELECT 
		price, product_name
		INTO
		v_price, v_product
	FROM products
	WHERE product_id = p_product_id;
	
-- checking stock and product availability in inventory	
	SELECT 
		COUNT(*) 
		INTO
		v_count
	FROM inventory
	WHERE 
		product_id = p_product_id
		AND 
		stock >= p_quantity;
		
	IF v_count > 0 THEN
	-- add into orders and order_items table
	-- update inventory
		INSERT INTO orders(order_id, order_date, customer_id, seller_id)
		VALUES
		(p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

		-- adding into order list
		INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sale)
		VALUES
		(p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, v_price*p_quantity);

		--updating inventory
		UPDATE inventory
		SET stock = stock - p_quantity
		WHERE product_id = p_product_id;
		
		RAISE NOTICE 'Thank you product: % sale has been added also inventory stock updates',v_product; 
	ELSE
		RAISE NOTICE 'Thank you for for your info the product: % is not available', v_product;
	END IF;
END;
$$
```



**Testing Store Procedure**
call add_sales
(
25005, 2, 5, 25004, 1, 14
);

---

## **Learning Outcomes**

This project enabled proficiency in several key areas:

- **Database Design:** Successfully designed and implemented a normalized database schema to organize data efficiently and minimize redundancy.
  
- **Data Cleaning & Preprocessing:** Gained expertise in cleaning and preprocessing real-world datasets by managing null values, duplicates, and ensuring data quality for reliable analysis.

- **Advanced SQL Techniques:** Applied advanced SQL techniques such as window functions, subqueries, CTEs, and complex joins to extract insights from the dataset and solve intricate business queries.

- **Business Analysis with SQL:** Conducted in-depth analysis to address critical business needs, such as identifying revenue patterns, customer segmentation, and optimizing inventory management.

- **Performance Optimization:** Developed skills in optimizing query performance, ensuring efficient handling of large datasets to deliver faster results and improve overall database efficiency.

## **Conclusion**

This advanced SQL project effectively showcases the ability to solve real-world e-commerce challenges through structured queries. It offers valuable insights into key operational areas, including improving customer retention, optimizing inventory, and streamlining logistics. By addressing these business problems, the project highlights how data-driven solutions can enhance decision-making and operational efficiency.

Through this experience, a deeper understanding of SQL's capabilities in tackling complex data problems was gained, demonstrating how it serves as a powerful tool for driving strategic business decisions in e-commerce.



### **Entity Relationship Diagram (ERD)**
![amazon_db_erd](https://github.com/user-attachments/assets/0c47e095-0d0b-4b36-88a6-7414b8496e3d)

## Contact

Author: [@Smit Rana](https://www.linkedin.com/in/smit98rana/) 
<p align="center">
	<img src="https://user-images.githubusercontent.com/74038190/214644145-264f4759-7633-441e-9d67-d8dda9d50d26.gif" width="200">
</p>

<div align="center">
  <a href="https://git.io/typing-svg">
    <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&pause=1000&center=true&vCenter=true&random=true&width=435&lines=I+hope+this+work+serves+you+well!" alt="Typing SVG" />
  </a>
</div>

<img src="https://user-images.githubusercontent.com/74038190/212284100-561aa473-3905-4a80-b561-0d28506553ee.gif" >
