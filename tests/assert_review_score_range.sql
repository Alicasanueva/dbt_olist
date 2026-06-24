-- Regla de rango de valores: Los scores solo pueden ser del 1 al 5
SELECT
    review_id,
    review_score
FROM {{ ref('stg_order_reviews') }}
WHERE review_score NOT BETWEEN 1 AND 5