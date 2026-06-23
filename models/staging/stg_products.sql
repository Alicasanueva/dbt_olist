WITH source AS (
    SELECT * FROM {{ source('raw', 'PRODUCTS') }}
),

renamed AS (
    SELECT
        TRIM(product_id)                                AS product_id,
        LOWER(TRIM(product_category_name))              AS product_category_name,
        TRY_TO_NUMBER(product_name_lenght)              AS product_name_length,
        TRY_TO_NUMBER(product_description_lenght)       AS product_description_length,
        TRY_TO_NUMBER(product_photos_qty)               AS product_photos_qty,
        TRY_TO_NUMBER(product_weight_g)                 AS product_weight_g,
        TRY_TO_NUMBER(product_length_cm)                AS product_length_cm,
        TRY_TO_NUMBER(product_height_cm)                AS product_height_cm,
        TRY_TO_NUMBER(product_width_cm)                 AS product_width_cm
    FROM source
)

SELECT * FROM renamed