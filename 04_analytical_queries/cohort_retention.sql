-- Cohort retention analysis
-- Groups customers by their first purchase month (cohort), then tracks
-- what percentage return in each subsequent month.
-- FIRST_VALUE() always pulls the cohort's month-0 size so later months
-- can express active users as a percentage of the original cohort.

WITH first_orders AS (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(created_at)) AS cohort_month
    FROM orders
    WHERE status NOT IN ('cancelled')
    GROUP BY user_id
),
monthly_activity AS (
    SELECT DISTINCT
        o.user_id,
        DATE_TRUNC('month', o.created_at) AS activity_month
    FROM orders o
    WHERE o.status NOT IN ('cancelled')
),
cohort_data AS (
    SELECT
        f.cohort_month,
        m.activity_month,
        COUNT(DISTINCT m.user_id)                        AS active_users,
        EXTRACT(MONTH FROM AGE(m.activity_month, f.cohort_month))::INT
                                                         AS months_since_first_order
    FROM first_orders f
    JOIN monthly_activity m ON f.user_id = m.user_id
    GROUP BY f.cohort_month, m.activity_month
)
SELECT
    cohort_month,
    months_since_first_order,
    active_users,
    FIRST_VALUE(active_users) OVER (
        PARTITION BY cohort_month
        ORDER BY months_since_first_order
    )                                                    AS cohort_size,
    ROUND(
        100.0 * active_users /
        FIRST_VALUE(active_users) OVER (
            PARTITION BY cohort_month
            ORDER BY months_since_first_order
        ),
    1)                                                   AS retention_pct
FROM cohort_data
ORDER BY cohort_month, months_since_first_order;
