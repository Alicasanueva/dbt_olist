/* WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

items_agg AS (
    SELECT
        order_id,
        SUM(total_item_value)       AS order_value,
        COUNT(*)                    AS total_items
    FROM {{ ref('fct_order_items') }}
    GROUP BY order_id
),

payments_agg AS (
    SELECT
        order_id,
        SUM(payment_value)          AS total_payment_value
    FROM {{ ref('stg_order_payments') }}
    WHERE payment_type != 'not_defined'
    GROUP BY order_id
),

final AS (
    SELECT
        o.order_id,
        c.customer_unique_id                AS customer_id,
        o.order_status,
        o.order_purchase_at,
        o.order_approved_at,
        o.order_delivered_carrier_at,
        o.order_delivered_customer_at,
        o.order_estimated_delivery_at,
        DATEDIFF('day',
            o.order_purchase_at,
            o.order_delivered_customer_at
        )                                   AS delivery_days,
        CASE
            WHEN o.order_delivered_customer_at IS NULL THEN NULL
            WHEN o.order_delivered_customer_at > o.order_estimated_delivery_at THEN 1
            ELSE 0
        END                                 AS is_late_delivery,
        COALESCE(i.order_value, 0)          AS order_value,
        COALESCE(i.total_items, 0)          AS total_items,
        COALESCE(p.total_payment_value, 0)  AS total_payment_value
    FROM orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN items_agg i
        ON o.order_id = i.order_id
    LEFT JOIN payments_agg p
        ON o.order_id = p.order_id
)

SELECT * FROM final */


/* Agrega antes de joinear — items_agg y payments_agg colapsan a grain de orden con GROUP BY order_id antes del join, evitando el fan-out
delivery_days — días desde compra hasta entrega real
is_late_delivery — NULL si nunca se entregó (orden cancelada etc.), 1 si llegó tarde, 0 si llegó a tiempo. El enunciado lo pide explícitamente así
COALESCE(..., 0) — si una orden no tiene items o pagos, suma 0 en vez de NULL
Lee de fct_order_items — reutiliza el trabajo ya hecho con ref() */


-- Lo modifico para crear bi_orders. Añado review_score a fct_orders haciendo join con stg_order_reviews.
WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM {{ ref('stg_order_reviews') }}
    GROUP BY order_id
),

items_agg AS (
    SELECT
        order_id,
        SUM(total_item_value)   AS order_value,
        COUNT(*)                AS total_items
    FROM {{ ref('fct_order_items') }}
    GROUP BY order_id
),

payments_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value
    FROM {{ ref('stg_order_payments') }}
    WHERE payment_type != 'not_defined'
    GROUP BY order_id
),

final AS (
    SELECT
        o.order_id,
        c.customer_unique_id                AS customer_id,
        o.order_status,
        o.order_purchase_at                 AS purchased_at,
        o.order_approved_at,
        o.order_delivered_carrier_at,
        o.order_delivered_customer_at,
        o.order_estimated_delivery_at,
        DATEDIFF('day',
            o.order_purchase_at,
            o.order_delivered_customer_at
        )                                   AS delivery_days,
        CASE
            WHEN o.order_delivered_customer_at IS NULL THEN NULL
            WHEN o.order_delivered_customer_at > o.order_estimated_delivery_at THEN 1
            ELSE 0
        END                                 AS is_late_delivery,
        COALESCE(i.order_value, 0)          AS order_value,
        COALESCE(i.total_items, 0)          AS total_items,
        COALESCE(p.total_payment_value, 0)  AS total_payment_value,
        r.review_score
    FROM orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN items_agg i
        ON o.order_id = i.order_id
    LEFT JOIN payments_agg p
        ON o.order_id = p.order_id
    LEFT JOIN reviews r
        ON o.order_id = r.order_id
)

SELECT * FROM final