WITH source AS (
    SELECT * FROM {{ source('raw', 'ORDER_PAYMENTS') }}
),

renamed AS (
    SELECT
        TRIM(order_id)                            AS order_id,
        TRY_TO_NUMBER(payment_sequential)         AS payment_sequential,
        TRIM(payment_type)                        AS payment_type,
        TRY_TO_NUMBER(payment_installments)       AS payment_installments,
        TRY_TO_DOUBLE(payment_value)              AS payment_value
    FROM source
)

SELECT * FROM renamed