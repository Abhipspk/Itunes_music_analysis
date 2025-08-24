-- Apple iTunes Music Analysis: Business Questions and SQL Queries

-- 1. Customer Analytics

-- 1.1 Which customers have spent the most money on music?
SELECT 
  c.customer_id,
  c.first_name,
  c.last_name,
  SUM(i.total) AS total_spent
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 10;

-- 1.2 What is the average customer lifetime value (total spending)?
SELECT AVG(customer_total) AS avg_lifetime_value
FROM (
  SELECT customer_id, SUM(total) as customer_total
  FROM Invoice
  GROUP BY customer_id
) as customer_totals;

-- 1.3 How many customers have made repeat purchases vs one-time purchases?
SELECT 
  CASE WHEN purchase_count > 1 THEN 'Repeat Purchasers' ELSE 'One-time Purchasers' END AS purchase_type,
  COUNT(*) AS customer_count
FROM (
  SELECT customer_id, COUNT(invoice_id) AS purchase_count
  FROM Invoice
  GROUP BY customer_id
) AS purchase_summary
GROUP BY purchase_type;

-- 1.4 Which country generates most revenue per customer?
SELECT c.country,
       AVG(i.total) AS avg_revenue_per_customer
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY avg_revenue_per_customer DESC;

-- 1.5 Customers inactive for last 6 months (assuming current date 2025-08-24)
SELECT c.customer_id, c.first_name, c.last_name, MAX(i.invoice_date) AS last_purchase_date
FROM Customer c
LEFT JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING MAX(i.invoice_date) < DATE_SUB('2025-08-24', INTERVAL 6 MONTH) OR MAX(i.invoice_date) IS NULL;

-- 2. Sales & Revenue Analysis

-- 2.1 Monthly revenue trends for last two years
SELECT DATE_FORMAT(invoice_date, '%Y-%m') AS month, SUM(total) AS monthly_revenue
FROM Invoice
WHERE invoice_date >= DATE_SUB('2025-08-24', INTERVAL 2 YEAR)
GROUP BY month
ORDER BY month;

-- 2.2 Average value of an invoice (purchase)
SELECT AVG(total) AS avg_invoice_value
FROM Invoice;

-- 2.3 [Add query for payment methods if data available]

-- 2.4 Revenue contribution by each sales representative (employee)
SELECT e.employee_id, e.first_name, e.last_name, SUM(i.total) AS total_revenue
FROM Employee e
JOIN Customer c ON e.employee_id = c.support_rep_id
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_revenue DESC;

-- 2.5 Peak sales months or quarters
SELECT QUARTER(invoice_date) AS quarter, YEAR(invoice_date) AS year, SUM(total) AS total_revenue
FROM Invoice
GROUP BY year, quarter
ORDER BY year, quarter;

-- 3. Product & Content Analysis

-- 3.1 Top revenue-generating tracks
SELECT t.track_id, t.name, SUM(il.unit_price * il.quantity) AS revenue
FROM Track t
JOIN Invoice_Line il ON t.track_id = il.track_id
GROUP BY t.track_id, t.name
ORDER BY revenue DESC
LIMIT 10;

-- 3.2 Most frequently purchased albums
SELECT a.album_id, a.title, COUNT(il.track_id) AS purchase_count
FROM Album a
JOIN Track t ON a.album_id = t.album_id
JOIN Invoice_Line il ON t.track_id = il.track_id
GROUP BY a.album_id, a.title
ORDER BY purchase_count DESC
LIMIT 10;

-- 3.3 Tracks or albums never purchased
-- Tracks never purchased
SELECT track_id, name
FROM Track
WHERE track_id NOT IN (SELECT DISTINCT track_id FROM Invoice_Line);

-- Albums never purchased
SELECT album_id, title
FROM Album
WHERE album_id NOT IN (
  SELECT DISTINCT album_id FROM Track
  WHERE track_id IN (SELECT DISTINCT track_id FROM Invoice_Line)
);

-- 3.4 Average price per track by genre
SELECT g.name AS genre, AVG(t.unit_price) AS avg_price
FROM Genre g
JOIN Track t ON g.genre_id = t.genre_id
GROUP BY g.name
ORDER BY avg_price DESC;

-- 3.5 Track count per genre with sales count
SELECT g.name AS genre,
       COUNT(t.track_id) AS track_count,
       COALESCE(SUM(il.quantity), 0) AS tracks_sold
FROM Genre g
LEFT JOIN Track t ON g.genre_id = t.genre_id
LEFT JOIN Invoice_Line il ON t.track_id = il.track_id
GROUP BY g.name
ORDER BY tracks_sold DESC;

-- 4. Artist & Genre Performance

-- 4.1 Top 5 highest-grossing artists
SELECT ar.artist_id, ar.name, SUM(il.unit_price * il.quantity) AS total_revenue
FROM Artist ar
JOIN Album al ON ar.artist_id = al.artist_id
JOIN Track t ON al.album_id = t.album_id
JOIN Invoice_Line il ON t.track_id = il.track_id
GROUP BY ar.artist_id, ar.name
ORDER BY total_revenue DESC
LIMIT 5;

-- 4.2 Popular genres by number of tracks sold and revenue
SELECT g.genre_id, g.name,
       COUNT(il.invoice_line_id) AS tracks_sold,
       SUM(il.unit_price * il.quantity) AS total_revenue
FROM Genre g
JOIN Track t ON g.genre_id = t.genre_id
LEFT JOIN Invoice_Line il ON t.track_id = il.track_id
GROUP BY g.genre_id, g.name
ORDER BY total_revenue DESC;

-- 4.3 Genre popularity by country (example: top genre per country revenue)
SELECT c.country, g.name AS genre, SUM(il.unit_price * il.quantity) AS revenue
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
JOIN Invoice_Line il ON i.invoice_id = il.invoice_id
JOIN Track t ON il.track_id = t.track_id
JOIN Genre g ON t.genre_id = g.genre_id
GROUP BY c.country, g.name
ORDER BY c.country, revenue DESC;

-- 5. Employee & Operational Efficiency

-- 5.1 Employees managing highest-spending customers
SELECT e.employee_id, e.first_name, e.last_name, SUM(i.total) AS total_customer_revenue
FROM Employee e
JOIN Customer c ON e.employee_id = c.support_rep_id
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_customer_revenue DESC;

-- 5.2 Average number of customers per employee
SELECT AVG(customer_counts.customer_count) AS avg_customers_per_employee
FROM (
  SELECT support_rep_id, COUNT(customer_id) AS customer_count
  FROM Customer
  GROUP BY support_rep_id
) AS customer_counts;

-- 5.3 Employee regions bringing most revenue (assuming employee location in country field)
SELECT e.country, SUM(i.total) AS total_revenue
FROM Employee e
JOIN Customer c ON e.employee_id = c.support_rep_id
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY e.country
ORDER BY total_revenue DESC;

-- 6. Geographic Trends

-- 6.1 Countries with highest number of customers
SELECT country, COUNT(customer_id) AS customer_count
FROM Customer
GROUP BY country
ORDER BY customer_count DESC;

-- 6.2 Revenue variation by region (country)
SELECT billing_country, SUM(total) AS total_revenue
FROM Invoice
GROUP BY billing_country
ORDER BY total_revenue DESC;

-- 7. Customer Retention & Purchase Patterns

-- 7.1 Distribution of purchase frequency per customer
SELECT purchase_count, COUNT(customer_id) AS num_customers
FROM (
  SELECT customer_id, COUNT(invoice_id) AS purchase_count
  FROM Invoice
  GROUP BY customer_id
) AS purchases
GROUP BY purchase_count
ORDER BY purchase_count;

-- 7.2 Average time between customer purchases
WITH customer_purchases AS (
  SELECT customer_id, invoice_date,
         LEAD(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date) AS next_purchase_date
  FROM Invoice
)
SELECT AVG(DATEDIFF(next_purchase_date, invoice_date)) AS avg_days_between_purchases
FROM customer_purchases
WHERE next_purchase_date IS NOT NULL;

-- 7.3 Percentage of customers purchasing tracks from more than one genre
WITH customer_genres AS (
  SELECT DISTINCT c.customer_id, t.genre_id
  FROM Customer c
  JOIN Invoice i ON c.customer_id = i.customer_id
  JOIN Invoice_Line il ON i.invoice_id = il.invoice_id
  JOIN Track t ON il.track_id = t.track_id
)
SELECT 
  (SELECT COUNT(DISTINCT customer_id) FROM customer_genres WHERE customer_id IN (
    SELECT customer_id FROM customer_genres GROUP BY customer_id HAVING COUNT(DISTINCT genre_id) > 1)
  ) * 100.0 / COUNT(DISTINCT customer_id) AS pct_customers_multi_genre
FROM customer_genres;

-- 8. Operational Optimization

-- 8.1 Most common combinations of tracks purchased together (top 10 pairs)
SELECT il1.track_id AS track1, il2.track_id AS track2, COUNT(*) AS pair_count
FROM Invoice_Line il1
JOIN Invoice_Line il2 ON il1.invoice_id = il2.invoice_id AND il1.track_id < il2.track_id
GROUP BY il1.track_id, il2.track_id
ORDER BY pair_count DESC
LIMIT 10;

-- 8.2 Pricing patterns leading to higher or lower sales (average quantity sold by unit price bands)
SELECT unit_price, AVG(quantity) AS avg_quantity_sold, COUNT(*) AS num_sales
FROM Invoice_Line
GROUP BY unit_price
ORDER BY unit_price;

-- 8.3 Trends of media type usage (increasing or decreasing sales over time)
SELECT mt.name AS media_type, DATE_FORMAT(i.invoice_date, '%Y-%m') AS month, COUNT(il.invoice_line_id) AS sales_count
FROM Invoice_Line il
JOIN Track t ON il.track_id = t.track_id
JOIN Media_Type mt ON t.media_type_id = mt.media_type_id
JOIN Invoice i ON il.invoice_id = i.invoice_id
GROUP BY mt.name, month
ORDER BY month, media_type;
