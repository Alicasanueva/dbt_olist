WITH source AS (
    SELECT * FROM {{ source('raw', 'GEOLOCATION') }}
),

filtered AS (
    SELECT
        TRIM(geolocation_zip_code_prefix)       AS zip_code_prefix,
        TRY_TO_DOUBLE(geolocation_lat)          AS latitude,
        TRY_TO_DOUBLE(geolocation_lng)          AS longitude,
        LOWER(TRIM(geolocation_city))           AS city,
        UPPER(TRIM(geolocation_state))          AS state
    FROM source
    WHERE TRY_TO_DOUBLE(geolocation_lat) BETWEEN -34 AND 5
      AND TRY_TO_DOUBLE(geolocation_lng) BETWEEN -74 AND -34
),

aggregated AS (
    SELECT
        zip_code_prefix,
        AVG(latitude)   AS latitude,       -- resuelvo el problema de duplicados. Cada zip code tenía ~52 filas con coordenadas ligeramente distintas. 
        AVG(longitude)  AS longitude,      -- colapso en una sola fila calculando el punto medio entre todas
        MAX(city)       AS city,
        MAX(state)      AS state
    FROM filtered
    GROUP BY zip_code_prefix
)

SELECT * FROM aggregated