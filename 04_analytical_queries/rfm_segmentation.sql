-- RFM customer segmentation (Recency, Frequency, Monetary value)
-- NTILE(5) scores each dimension 1-5 across all customers.
-- Scores are summed and mapped to Champion / Loyal / At Risk / Lost.

WITH rfm_raw AS (
    SELECT
        u.user_id,
        u.email,
        MAX(o.created_at)                AS last_order_date,
        COUNT(DISTINCT o.order_id)       AS order_count,
        SUM(oi.quantity * oi.unit_price) AS total_spent
    FROM users u
    JOIN orders o       ON u.user_id  = o.user_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY u.user_id, u.email
),
rfm_scored AS (
    SELECT *,
        EXTRACT(DAY FROM NOW() - last_order_date)     AS days_since_last_order,
        NTILE(5) OVER (ORDER BY last_order_date DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY order_count DESC)     AS frequency_score,
        NTILE(5) OVER (ORDER BY total_spent DESC)     AS monetary_score
    FROM rfm_raw
)
SELECT
    user_id,
    email,
    days_since_last_order,
    order_count,
    ROUND(total_spent::NUMERIC, 2)                      AS total_spent,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score)  AS rfm_total,
    CASE
        WHEN (recency_score + frequency_score + monetary_score) >= 13 THEN 'Champion'
        WHEN (recency_score + frequency_score + monetary_score) >= 10 THEN 'Loyal'
        WHEN (recency_score + frequency_score + monetary_score) >= 7  THEN 'At Risk'
        ELSE 'Lost'
    END                                                 AS customer_segment
FROM rfm_scored
ORDER BY rfm_total DESC;
