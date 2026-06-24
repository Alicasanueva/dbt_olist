-- Regla de integridad temporal: delivery date can't precede purchase date
SELECT
    order_id,
    order_purchase_at,
    order_delivered_customer_at
FROM {{ ref('fct_orders') }}
WHERE order_delivered_customer_at < order_purchase_at