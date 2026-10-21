INSERT INTO pipeline_logs
(
    run_id,
    business_key,
    accion,
    row_id_t,
    row_id_t1
)
WITH ambiguas AS (
    SELECT
        business_key
    FROM
        movimientos_dia_t
    WHERE
        business_key IS NOT NULL
    GROUP BY
        business_key
    HAVING
        COUNT(*) > 1
    UNION
    SELECT
        business_key
    FROM
        movimientos_dia_t1
    WHERE
        business_key IS NOT NULL
    GROUP BY
        business_key
    HAVING
        COUNT(*) > 1
),
comparables_t AS (
    SELECT
        *
    FROM
        movimientos_dia_t
    WHERE
        business_key IS NOT NULL
        AND business_key NOT IN (SELECT business_key FROM ambiguas)
),
comparables_t1 AS (
    SELECT
        *
    FROM
        movimientos_dia_t1
    WHERE
        business_key IS NOT NULL
        AND business_key NOT IN (SELECT business_key FROM ambiguas)
),
acciones AS (
    SELECT
        COALESCE(t.business_key, s.business_key) AS business_key,
        CASE
            WHEN t.row_id IS NULL THEN 'INSERTAR'
            WHEN s.row_id IS NULL THEN 'ELIMINAR'
            WHEN t.row_hash IS DISTINCT FROM s.row_hash THEN 'ACTUALIZAR'
            ELSE 'OMITIR'
        END AS accion,
        t.row_id AS row_id_t,
        s.row_id AS row_id_t1
    FROM comparables_t AS t
    FULL OUTER JOIN comparables_t1 AS s USING (business_key)
    UNION ALL
    SELECT
        business_key,
        CASE
            WHEN business_key IS NULL THEN 'SIN_LLAVE'
            ELSE 'AMBIGUO'
        END,
        row_id,
        NULL
    FROM
        movimientos_dia_t
    WHERE
        business_key IS NULL OR business_key IN (SELECT business_key FROM ambiguas)
    UNION ALL
    SELECT
        business_key,
        CASE
            WHEN business_key IS NULL THEN 'SIN_LLAVE'
            ELSE 'AMBIGUO'
        END,
        NULL,
        row_id
    FROM
        movimientos_dia_t1
    WHERE
        business_key IS NULL OR business_key IN (SELECT business_key FROM ambiguas)
)
SELECT ?, business_key, accion, row_id_t, row_id_t1
FROM acciones;
