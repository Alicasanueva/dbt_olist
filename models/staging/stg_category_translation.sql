WITH source AS (
    SELECT * FROM {{ source('raw', 'CATEGORY_TRANSLATION') }}
),

renamed AS (
    SELECT
        LOWER(TRIM(product_category_name))          AS product_category_name,
        LOWER(TRIM(product_category_name_english))  AS product_category_name_english
    FROM source
)

SELECT * FROM renamed