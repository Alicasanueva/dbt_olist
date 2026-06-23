WITH source AS (
    SELECT * FROM {{ source('raw', 'ORDER_REVIEWS') }}
),

renamed AS (
    SELECT
        TRIM(review_id)                                 AS review_id,
        TRIM(order_id)                                  AS order_id,
        TRY_TO_NUMBER(review_score)                     AS review_score,
        NULLIF(TRIM(review_comment_title), '')          AS review_comment_title,
        NULLIF(TRIM(review_comment_message), '')        AS review_comment_message,
        TRY_TO_TIMESTAMP(review_creation_date)          AS review_created_at,
        TRY_TO_TIMESTAMP(review_answer_timestamp)       AS review_answered_at
    FROM source
)

SELECT * FROM renamed