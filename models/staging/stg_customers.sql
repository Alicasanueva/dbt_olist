WITH source AS (
    SELECT * FROM {{ source('raw', 'CUSTOMERS') }}
),

renamed AS (
    SELECT
        TRIM(customer_id)            AS customer_id,
        TRIM(customer_unique_id)     AS customer_unique_id,
        TRIM(customer_zip_code_prefix)   AS zip_code_prefix,
        LOWER(TRIM(customer_city))   AS city,
        UPPER(TRIM(customer_state))  AS state
    FROM source
)

SELECT * FROM renamed