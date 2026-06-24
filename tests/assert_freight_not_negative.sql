-- El coste de envío nunca puede ser negativo
SELECT
    order_id,
    order_item_id,
    freight_value
FROM {{ ref('fct_order_items') }}
WHERE freight_value < 0