WITH source AS (
    SELECT * FROM {{ source('raw', 'ORDERS') }}
),

renamed AS (
    SELECT
        TRIM(order_id)                                        AS order_id,
        TRIM(customer_id)                                     AS customer_id,
        TRIM(order_status)                                    AS order_status,
        TRY_TO_TIMESTAMP(order_purchase_timestamp)            AS order_purchase_at,
        TRY_TO_TIMESTAMP(order_approved_at)                   AS order_approved_at,
        TRY_TO_TIMESTAMP(order_delivered_carrier_date)        AS order_delivered_carrier_at,
        TRY_TO_TIMESTAMP(order_delivered_customer_date)       AS order_delivered_customer_at,
        TRY_TO_TIMESTAMP(order_estimated_delivery_date)       AS order_estimated_delivery_at
    FROM source
)

SELECT * FROM renamed