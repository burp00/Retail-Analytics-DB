-- Monthly revenue trend
-- DATE_TRUNC groups timestamps into monthly buckets.
-- COUNT(DISTINCT) avoids double-counting customers with multiple orders.

SELECT
    DATE_TRUNC('month', o.created_at)    AS month,
    COUNT(DISTINCT o.order_id)           AS total_orders,
    COUNT(DISTINCT o.user_id)            AS unique_customers,
    SUM(oi.quantity * oi.unit_price)     AS revenue,
    AVG(oi.quantity * oi.unit_price)     AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY DATE_TRUNC('month', o.created_at)
ORDER BY month;
