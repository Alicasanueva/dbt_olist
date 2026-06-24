-- Regla de validez numérica: Un pedido con valor negativo es imposible en la realidad
SELECT
    order_id,
    order_value
FROM {{ ref('fct_orders') }}
WHERE order_value < 0