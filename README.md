<h1 align="center"> Digital Sales Insights and Optimization </h1>
<br>
<p align="center">
  <img src="https://github.com/user-attachments/assets/2edc6b97-01b3-4e95-9cee-36fb8dfee025" width="230">
</p>

<div align="justify"> 
	
### Introduction

<p align="justify"> In the fast-changing world of e-commerce, businesses are constantly looking for ways to refine their sales strategies, boost customer satisfaction, and enhance inventory management. This project centers on analyzing Amazon's e-commerce sales performance through a relational database model built in PostgreSQL. By employing advanced SQL queries, we seek to uncover valuable insights from various interconnected tables representing customers, sellers, orders, shipping, payments, products, categories, order items, and inventory. </p>

<p align="justify"> The analysis covers a wide range of performance metrics, including top-selling products, revenue by category, customer lifetime value (CLTV), and inventory stock alerts. By focusing on these essential elements, the project aims to deliver actionable insights that can assist stakeholders in making informed decisions to stimulate sales growth and improve operational efficiency. </p>

### Problem Statement

Although Amazon's e-commerce platform offers a vast amount of data, extracting actionable insights necessitates advanced data analysis techniques. This project addresses several key challenges:

- **Sales Performance Metrics**: Analyzing which products and categories have the greatest impact on overall sales, and identifying trends in customer purchasing behavior over time.
  
- **Customer Insights**: Evaluating customer activity to uncover engagement and retention opportunities, such as identifying inactive customers and differentiating between new and returning customers based on their purchasing habits.
  
- **Inventory Management**: Monitoring stock levels to pinpoint potential inventory shortages that could result in lost sales opportunities, while also understanding the relationship between inventory levels and sales trends.
  
- **Shipping and Payment Efficiency**: Analyzing shipping performance and payment success rates to identify bottlenecks in the order fulfillment process and enhance overall customer satisfaction.
  
- **Seller Performance Evaluation**: Evaluating seller performance based on total sales and order success rates to identify top performers and areas needing improvement.

Through a series of complex SQL queries, this project aims to deliver comprehensive insights into these challenges, empowering stakeholders to make data-driven decisions that improve the overall performance of Amazon's e-commerce platform.


### Objectives
1. **Create a Comprehensive PostgreSQL Database Schema**: Design a robust database schema that effectively represents the diverse entities and their relationships within Amazon's e-commerce ecosystem.

2. **Execute Advanced SQL Queries**: Implement intricate SQL queries to extract actionable insights regarding sales performance, customer behavior, inventory management, shipping efficiency, and seller performance.

3. **Deliver a Detailed Findings Report**: Compile the results into a thorough report that emphasizes key metrics, trends, and recommendations aimed at enhancing Amazon's e-commerce sales strategies.


### Entity Relationship Diagram
![amazon_db](https://github.com/user-attachments/assets/1f1f9a2e-2099-41f3-8407-1053a744ede9)


### Database Setup & Design

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

### **ERD generated by _pgAdmin 4_ at the end of schema creation.**

![amazon_db_erd](https://github.com/user-attachments/assets/0c47e095-0d0b-4b36-88a6-7414b8496e3d)

### Solving Business Problems

__1. Top Selling Products__ <br>
Query the top 10 products by total sales value. <br>
__Challenge__ :  Include product name, total quantity sold, and total sales value. <br>

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

__2. Revenue by Category__ <br>
Calculate total revenue generated by each product category. <br>
__Challenge__ :  Include the percentage contribution of each category to total revenue. <br>

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

__3. Average Order Value (AOV)__ <br>
Compute the average order value for each customer. <br>
__Challenge__ :  Include only customers with more than 5 orders. <br>

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

__4. Monthly Sales Trend__ <br>
Query monthly total sales over the past year. <br>
__Challenge__ :  Display the sales trend, grouping by month, return current_month sale, last month sale! <br>

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


__5. Customers with No Purchases__  <br>
Find customers who have registered but never placed an order. <br>
__Challenge__ :  List customer details and the time since their registration. <br>

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

__6. Least-Selling Categories by State__  <br>
Identify the least-selling product category for each state. <br>
__Challenge__ :  Include the total sales for that category within each state. <br>

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

__7. Customer Lifetime Value (CLTV)__ <br>
Calculate the total value of orders placed by each customer over their lifetime. <br>
__Challenge__ :  Rank customers based on their CLTV.  <br>

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

__8. Inventory Stock Alerts__ <br>
Query products with stock levels below a certain threshold (e.g., less than 10 units). <br>
__Challenge__ :  Include last restock date and warehouse information. <br>

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

__9. Shipping Delays__  <br>
Identify orders where the shipping date is later than 3 days after the order date. <br>
__Challenge__ :  Include customer, order details, and delivery provider. <br>

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

__10. Payment Success Rate__ <br>
Calculate the percentage of successful payments across all orders. <br>
__Challenge__ :  Include breakdowns by payment status (e.g., failed, pending). <br>

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

__11. Top Performing Sellers__ <br>
Find the top 5 sellers based on total sales value. <br>
__Challenge__ :  Include both successful and failed orders, and display their percentage of successful orders. <br>

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

__12. Product Profit Margin__  <br>
Calculate the profit margin for each product (difference between price and cost of goods sold). <br>
__Challenge__ :  Rank products by their profit margin, showing highest to lowest. <br>
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

__13. Most Returned Products__  <br>
Query the top 10 products by the number of returns. <br>
__Challenge__ :  Display the return rate as a percentage of total units sold for each product. <br>

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

__14. Orders Pending Shipment__  <br>
Find orders that have been paid but are still pending shipment. <br>
__Challenge__ :  Include order details, payment date, and customer information. <br>

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

__15. Inactive Sellers__ <br>
Identify sellers who haven’t made any sales in the last 6 months. <br>
__Challenge__ :  Show the last sale date and total sales from those sellers. <br>

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

__16. Ienditfy customers into returning or new__ <br>
If the customer has done more than 5 return categorize them as returning otherwise new <br>
__Challenge__ :  List customers id, name, total orders, total returns <br>

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

__17. Top 5 Customers by Orders in Each State__ <br>
Identify the top 5 customers with the highest number of orders for each state. <br>
__Challenge__ :  Include the number of orders and total sales for each customer. <br>

```sql
SELECT
	CONCAT(c.first_name, ' ', c.last_name) AS "Name",
	c.state AS "State",
	COUNT(o.order_id) AS "No. of Orders",
	ROUND(SUM(oi.total_sales)::numeric, 2) AS "Total Sales",
	DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) AS "Rank"
FROM 
	orders AS o
JOIN 
	customers AS c ON c.customer_id = o.customer_id
JOIN 
	order_items AS oi ON o.order_id = oi.order_id
GROUP BY 
	c.first_name, c.last_name, c.state
ORDER BY 
	"State", "Rank";
```

__18. Revenue by Shipping Provider__ <br>
Calculate the total revenue handled by each shipping provider. <br>
__Challenge__ :  Include the total number of orders handled and the average delivery time for each provider. <br>

```sql
SELECT 
    s.shipping_providers AS "Shipment Providers",
    COUNT(o.order_id) AS "Orders Handled",
    ROUND(SUM(oi.total_sales)::numeric, 2) AS "Total Sales",
	-- Delivery date should fall somewhere between the shipping date and return date
    -- (s.shipping_date + (s.return_date - s.shipping_date)) AS "Delivery Date", 
    COALESCE(ROUND(AVG((s.shipping_date + (s.return_date - s.shipping_date) / 2) - s.shipping_date)::numeric, 2), 0) AS "Avg Delivery Time"
FROM 
    order_items AS oi
JOIN 
    orders AS o ON oi.order_id = o.order_id
JOIN 
    shipping AS s ON s.order_id = o.order_id
GROUP BY 
    s.shipping_providers;
```

__19. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)__ <br>
__Challenge__ :  Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result <br>
__Note__ : Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year) <br>

```sql
WITH last_year_sale AS (
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.total_sales)::numeric, 2) AS revenue
    FROM
        products AS p
    JOIN 
        order_items AS oi ON p.product_id = oi.product_id
    JOIN 
        orders AS o ON oi.order_id = o.order_id
    WHERE 
        EXTRACT(YEAR FROM o.order_date) = 2022
    GROUP BY 
        p.product_id, p.product_name
),
current_year_sale AS (
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.total_sales)::numeric, 2) AS revenue
    FROM
        products AS p
    JOIN 
        order_items AS oi ON p.product_id = oi.product_id
    JOIN 
        orders AS o ON oi.order_id = o.order_id
    WHERE 
        EXTRACT(YEAR FROM o.order_date) = 2023
    GROUP BY 
        p.product_id, p.product_name
)

SELECT
    cs.product_id AS "Product ID",
    cs.product_name AS "Name",
    ls.revenue AS "Last Year Revenue",
    cs.revenue AS "Current Year Revenue",
    (ls.revenue - cs.revenue) AS "Revenue Difference",
    ROUND(((ls.revenue - cs.revenue) / ls.revenue) * 100, 2) AS "Revenue Decrease Ratio"
FROM 
    last_year_sale AS ls
JOIN 
    current_year_sale AS cs ON ls.product_id = cs.product_id
WHERE 
    ls.revenue > cs.revenue 
ORDER BY 
    "Revenue Decrease Ratio" DESC
LIMIT 10;
```

__20. Stored Procedure__
Create a stored procedure that, when a product is sold, performs the following actions: <br>
- Insert a new sales record into the orders and order_items tables. <br>
- Update the inventory table to reduce the stock based on the product and quantity purchased. <br>
- The procedure should ensure that the stock is adjusted immediately after recording the sale. <br>

```SQL
CREATE OR REPLACE PROCEDURE process_order_and_update_inventory 
(
    p_order_id INT,         -- Order ID provided for the new order
    p_customer_id INT,      -- Customer ID associated with the order
    p_seller_id INT,        -- Seller ID associated with the order
    p_order_item_id INT,    -- Unique Order Item ID for each product in the order
    p_product_id INT,       -- Product ID of the item being ordered
    p_quantity INT          -- Quantity of the product being ordered
)
LANGUAGE plpgsql
AS $$

DECLARE 
    -- Variables to store product details and stock check result
    v_count INT;           
    v_price FLOAT;          
    v_product VARCHAR(50);  

BEGIN
    -- Retrieve product name and price based on the provided product ID
    SELECT 
        price, 
        product_name
    INTO
        v_price, 
        v_product
    FROM products
    WHERE product_id = p_product_id;
    
    -- Check inventory for product availability with the required quantity
    SELECT 
        COUNT(*) 
    INTO
        v_count
    FROM inventory
    WHERE 
        product_id = p_product_id   -- Check for the specified product
        AND stock >= p_quantity;    -- Ensure available stock is equal to or greater than the ordered quantity
        
    -- If sufficient stock is available, proceed with order and update inventory
    IF v_count > 0 THEN
        
		-- Insert the new order details into the 'orders' table
        INSERT INTO orders(order_id, order_date, customer_id, seller_id)
        VALUES
        (p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

        -- Insert product details into the 'order_items' table, calculating total sales
        INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)
        VALUES
        (p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, v_price * p_quantity);

        -- Update the 'inventory' table to reduce stock by the ordered quantity
        UPDATE inventory
        SET stock = stock - p_quantity
        WHERE product_id = p_product_id;
        
        -- Display a success message indicating the product sale has been recorded and stock updated
        RAISE NOTICE 'Thank you, the product % sale has been added and inventory stock has been updated.', v_product; 
    ELSE
        -- If stock is insufficient, display a message indicating the product is unavailable
        RAISE NOTICE 'Unfortunately, the product: % is not available', v_product;
    END IF;

END;
$$;
```

### Before 
![before](https://github.com/user-attachments/assets/6a8dfe47-049d-433c-828e-2d8bfeb99dfa)

```sql
-- Testing Store Procedure
call process_order_and_update_inventory (24001, 10 , 3, 24007, 38, 11);
```

### After

![after](https://github.com/user-attachments/assets/6e936929-fadc-4853-92ae-3c0570478121)


### Learning Outcomes

- **Joins**: Achieved mastery in using joins to efficiently retrieve data from multiple related tables.

- **Subqueries and CTEs**: Gained expertise in utilizing subqueries and Common Table Expressions (CTEs) to simplify and organize complex queries, enhancing readability and maintainability.

- **Aggregation Functions**: Developed proficiency in applying aggregation functions such as SUM, COUNT, and AVG to summarize data effectively.

- **Window Functions**: Gained an understanding of how to use window functions, including DENSE_RANK(), to rank and calculate cumulative statistics, as well as the LAG() function for comparisons between current and previous rows.

- **Conditional Logic**: Implemented CASE statements to categorize data and apply logical conditions within queries.

- **Procedural Logic in pgSQL**: Created stored procedures using pgSQL for improved reusability and handling of procedural logic, including error handling and validation.

- **Date Filtering**: Applied date functions (EXTRACT(), INTERVAL) to filter data based on specific time frames or periods.

- **Efficient Stored Procedures**: Developed modular and reusable stored procedures to manage complex database transactions with dynamic input.

- **Query Optimization**: Learned techniques for writing optimized queries that reduce redundancy, enhance performance, and avoid unnecessary complexity.


### **Conclusion**

In conclusion, this project highlights the significant potential of advanced data analysis techniques in optimizing e-commerce operations, particularly within Amazon's platform. By developing a robust PostgreSQL database schema and executing complex SQL queries, we have been able to derive valuable insights into sales performance, customer behavior, inventory management, shipping efficiency, and seller performance.

The learning outcomes achieved throughout this process—ranging from mastering joins and subqueries to implementing procedural logic and query optimization—have equipped us with the skills necessary to tackle complex data challenges effectively. The findings from our analysis not only illuminate key metrics and trends but also offer actionable recommendations that can enhance Amazon's e-commerce sales strategies.

Moving forward, the insights gained from this project can serve as a foundation for continuous improvement, enabling stakeholders to make informed, data-driven decisions that drive growth and enhance customer satisfaction in an increasingly competitive landscape.

</div>
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
