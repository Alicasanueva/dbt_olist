WITH order_items AS (
    SELECT * FROM {{ ref('fct_order_items') }}
),

orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
),

products AS (
    SELECT * FROM {{ ref('dim_products') }}
),

customers AS (
    SELECT * FROM {{ ref('dim_customers') }}
),

final AS (
    SELECT
        c.customer_state,
        p.product_category_english,
        ROUND(AVG(o.review_score), 2)                           AS avg_review_score,
        COUNT(*)                                                AS total_orders,
        SUM(CASE WHEN o.review_score <= 2 THEN 1 ELSE 0 END)   AS negative_reviews,
        ROUND(
            SUM(CASE WHEN o.review_score <= 2 THEN 1 ELSE 0 END)
            / COUNT(*) * 100
        , 2)                                                    AS pct_negative_reviews
    FROM order_items oi
    LEFT JOIN orders o
        ON oi.order_id = o.order_id
    LEFT JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN customers c
        ON oi.customer_unique_id = c.customer_unique_id
    WHERE o.review_score IS NOT NULL
    GROUP BY
        c.customer_state,
        p.product_category_english
)

SELECT * FROM final


/* avg_review_score — score medio por estado y categoría → heat map
pct_negative_reviews — % de reviews negativas (score 1-2) por categoría → KPI libre
Agrupado por customer_state y product_category_english */