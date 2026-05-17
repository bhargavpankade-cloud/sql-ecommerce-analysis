CREATE DATABASE ecommerce_db1;

CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    city          VARCHAR(50),
    state         VARCHAR(50),
    segment       VARCHAR(30)
);

CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(150),
    category      VARCHAR(50),
    sub_category  VARCHAR(50)
);

CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT REFERENCES customers(customer_id),
    product_id    INT REFERENCES products(product_id),
    order_date    DATE,
    quantity      INT,
    discount      DECIMAL(4,2),
    sales         DECIMAL(10,2),
    profit        DECIMAL(10,2),
    region        VARCHAR(30)
);

INSERT INTO customers VALUES
(1,'Priya Sharma','Mumbai','Maharashtra','Consumer'),
(2,'Rahul Gupta','Delhi','Delhi','Corporate'),
(3,'Anita Patel','Bengaluru','Karnataka','Consumer'),
(4,'Kiran Rao','Chennai','Tamil Nadu','Home Office'),
(5,'Suresh Mehta','Hyderabad','Telangana','Corporate'),
(6,'Divya Nair','Pune','Maharashtra','Consumer'),
(7,'Amit Joshi','Kolkata','West Bengal','Consumer'),
(8,'Meera Singh','Jaipur','Rajasthan','Corporate');

INSERT INTO products VALUES
(1,'Laptop Pro 15','Technology','Computers'),
(2,'Office Chair Ergonomic','Furniture','Chairs'),
(3,'Stapler Heavy Duty','Office Supplies','Fasteners'),
(4,'Wireless Mouse','Technology','Accessories'),
(5,'Bookcase 5-Shelf','Furniture','Bookcases'),
(6,'Printer Ink Set','Office Supplies','Supplies'),
(7,'Monitor 27 inch','Technology','Monitors'),
(8,'Desk Lamp LED','Office Supplies','Appliances');

INSERT INTO orders VALUES
(1,1,1,'2024-01-15',2,0.10,135000,18000,'West'),
(2,2,2,'2024-01-20',4,0.05,45600,5200,'North'),
(3,3,3,'2024-02-01',10,0.20,3600,-200,'South'),
(4,4,4,'2024-02-10',5,0.00,6000,1800,'South'),
(5,5,1,'2024-02-15',1,0.15,63750,7200,'South'),
(6,6,7,'2024-03-01',3,0.10,48600,9200,'West'),
(7,7,5,'2024-03-05',2,0.30,11900,-800,'East'),
(8,8,6,'2024-03-10',6,0.00,13200,3100,'North'),
(9,1,4,'2024-03-20',8,0.05,9120,2400,'West'),
(10,2,7,'2024-04-01',2,0.20,28800,4100,'North'),
(11,3,1,'2024-04-10',1,0.00,75000,12000,'South'),
(12,4,6,'2024-04-15',4,0.10,7920,1800,'South'),
(13,5,2,'2024-05-01',2,0.15,20400,2100,'South'),
(14,6,3,'2024-05-10',20,0.25,6750,-500,'West'),
(15,7,4,'2024-05-20',3,0.00,3600,1100,'East');

-- Total sales, profit, and orders (basic KPIs)
SELECT
    COUNT(DISTINCT order_id)        AS total_orders,
    SUM(sales)                      AS total_sales,
    SUM(profit)                     AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2) AS profit_margin_pct
FROM orders;

-- Sales by category using JOIN
SELECT
    p.category,
    COUNT(o.order_id)               AS orders,
    SUM(o.sales)                    AS total_sales,
    SUM(o.profit)                   AS total_profit,
    ROUND(AVG(o.discount)*100, 1)   AS avg_discount_pct
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC;

-- Top 5 customers by revenue
SELECT
    c.customer_name,
    c.city,
    c.segment,
    SUM(o.sales)   AS total_spent,
    SUM(o.profit)  AS total_profit
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name, c.city, c.segment
ORDER BY total_spent DESC
LIMIT 5;

-- Region-wise performance
SELECT
    region,
    SUM(sales)                           AS total_sales,
    SUM(profit)                          AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100,2)  AS profit_margin_pct,
    COUNT(DISTINCT customer_id)          AS unique_customers
FROM orders
GROUP BY region
ORDER BY total_profit DESC;

-- Discount impact analysis (subquery)
SELECT
    discount_bucket,
    COUNT(*)           AS orders,
    SUM(sales)         AS total_sales,
    ROUND(AVG(profit), 2) AS avg_profit
FROM (
    SELECT *,
        CASE
            WHEN discount = 0        THEN 'No Discount'
            WHEN discount <= 0.15    THEN 'Low (1-15%)'
            WHEN discount <= 0.30    THEN 'Medium (16-30%)'
            ELSE                          'High (31%+)'
        END AS discount_bucket
    FROM orders
) sub
GROUP BY discount_bucket
ORDER BY avg_profit DESC;

-- Running total sales using Window Function
SELECT
    order_date,
    order_id,
    sales,
    SUM(sales) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_sales
FROM orders
ORDER BY order_date;

 -- Rank customers by spend using RANK()
 SELECT
    c.customer_name,
    c.segment,
    SUM(o.sales)  AS total_sales,
    RANK() OVER (
        PARTITION BY c.segment
        ORDER BY SUM(o.sales) DESC
    ) AS rank_in_segment
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name, c.segment
ORDER BY c.segment, rank_in_segment;

-- Products with negative profit (loss leaders)
WITH product_performance AS (
    SELECT
        p.product_name,
        p.category,
        SUM(o.sales)   AS total_sales,
        SUM(o.profit)  AS total_profit,
        AVG(o.discount) AS avg_discount
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.product_name, p.category
)
SELECT *,
    CASE WHEN total_profit < 0 THEN 'Loss-making' ELSE 'Profitable' END AS status
FROM product_performance
WHERE total_profit < 0
ORDER BY total_profit ASC;

-- Customer segment comparison (advanced CTE)
WITH segment_stats AS (
    SELECT
        c.segment,
        COUNT(DISTINCT o.customer_id)              AS customers,
        COUNT(o.order_id)                          AS orders,
        ROUND(SUM(o.sales)/COUNT(DISTINCT o.customer_id),2)
                                                   AS avg_revenue_per_customer,
        ROUND(SUM(o.profit)/SUM(o.sales)*100, 2)  AS profit_margin_pct
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.segment
)
SELECT *,
    RANK() OVER (ORDER BY profit_margin_pct DESC) AS margin_rank
FROM segment_stats;