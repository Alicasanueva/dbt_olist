SELECT
    o.order_id,
    c.customer_state,
    DATE_TRUNC('month', o.purchased_at)::DATE       AS purchase_month,
    o.order_value,
    o.is_late_delivery,
    o.review_score
FROM {{ ref('fct_orders') }} o
LEFT JOIN {{ ref('dim_customers') }} c
    ON o.customer_id = c.customer_id