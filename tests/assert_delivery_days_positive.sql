-- Un pedido no puede tardar días negativos en entregarse
SELECT
    order_id,
    delivery_days
FROM {{ ref('fct_orders') }}
WHERE delivery_days < 0