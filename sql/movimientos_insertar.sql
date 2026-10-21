INSERT INTO {table_name}
(
    id_cliente,
    date,
    raw_date,
    product,
    type,
    raw_type,
    fund,
    amount,
    description,
    commercial_name,
    business_key,
    row_hash
)
WITH normalizados AS
(
    SELECT
        NULLIF(TRIM(CAST(a.id_cliente AS VARCHAR)), '') AS id_cliente,
        CASE
            WHEN a.date IS NULL OR a.date = '' THEN NULL
            WHEN regexp_full_match(a.date, '[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}') THEN TRY_STRPTIME(a.date, '%Y-%m-%d')::DATE
            WHEN regexp_full_match(a.date, '[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}') THEN TRY_STRPTIME(a.date, '%d/%m/%Y')::DATE
            WHEN regexp_full_match(a.date, '[0-9]{{4}}/[0-9]{{2}}/[0-9]{{2}}') THEN TRY_STRPTIME(a.date, '%Y/%m/%d')::DATE
            WHEN regexp_full_match(a.date, '[0-9]{{2}}-[0-9]{{2}}-[0-9]{{4}}') THEN TRY_STRPTIME(a.date, '%d-%m-%Y')::DATE
            ELSE NULL
        END AS date,
        CAST(a.date AS VARCHAR) AS raw_date,
        CAST(a.product AS VARCHAR) AS product,
        CAST(b.tipo AS VARCHAR) AS type,
        CAST(a.type AS VARCHAR) AS raw_type,
        CAST(a.fund AS VARCHAR) AS fund,
        TRY_CAST(a.amount AS DECIMAL(20, 4)) AS amount,
        CAST(a.description AS VARCHAR) AS description,
        CAST(a.commercial_name AS VARCHAR) AS commercial_name
    FROM
        read_parquet('{file}') AS a
    LEFT JOIN
        tipos_movimientos AS b
    ON
        UPPER(STRIP_ACCENTS(TRIM(CAST(a.type AS VARCHAR)))) = b.raw_tipo
)
SELECT
    normalizados.*,
    CASE
        WHEN id_cliente IS NOT NULL AND date IS NOT NULL AND type IS NOT NULL THEN SHA256
        (
            to_json
            (
                struct_pack
                (
                    id_cliente := id_cliente,
                    date := date,
                    product := product,
                    type := type,
                    fund := fund,
                    commercial_name := commercial_name
                )
            )::VARCHAR
        )
    ELSE
        NULL
    END AS business_key,
    SHA256
    (
        to_json
        (
            struct_pack
            (
                id_cliente := id_cliente,
                date := date,
                product := product,
                type := type,
                fund := fund,
                amount := amount,
                description := description,
                commercial_name := commercial_name,
                raw_date_fallback := CASE WHEN date IS NULL THEN raw_date ELSE NULL END,
                raw_type_fallback := CASE WHEN type IS NULL THEN raw_type ELSE NULL END
            )
        )::VARCHAR
    ) AS row_hash
FROM normalizados;
