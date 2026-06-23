WITH source AS (
    SELECT * FROM {{ source('raw', 'ORDER_ITEMS') }}
),

renamed AS (
    SELECT
        TRIM(order_id)                          AS order_id,
        TRY_TO_NUMBER(order_item_id)            AS order_item_id,
        TRIM(product_id)                        AS product_id,
        TRIM(seller_id)                         AS seller_id,
        TRY_TO_TIMESTAMP(shipping_limit_date)   AS shipping_limit_at,
        TRY_TO_DOUBLE(price)                    AS price,
        TRY_TO_DOUBLE(freight_value)            AS freight_value
    FROM source
)

SELECT * FROM renamed