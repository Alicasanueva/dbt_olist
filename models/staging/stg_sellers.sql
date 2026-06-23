WITH source AS (
    SELECT * FROM {{ source('raw', 'SELLERS') }}
),

renamed AS (
    SELECT
        TRIM(seller_id)                           AS seller_id,
        TRIM(seller_zip_code_prefix)              AS zip_code_prefix,
        LOWER(TRIM(seller_city))                  AS city,
        UPPER(TRIM(seller_state))                 AS state
    FROM source
)

SELECT * FROM renamed