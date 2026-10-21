INSERT INTO pipeline_logs
(
    business_key,
    accion
)
SELECT
    COALESCE(s.business_key, t.business_key) AS business_key,
    CASE
        WHEN t.business_key IS NULL THEN 'INSERTAR'
        WHEN s.business_key IS NULL THEN 'ELIMINAR'
        WHEN
            t.row_hash IS DISTINCT FROM s.row_hash
            OR t.id_cliente IS DISTINCT FROM s.id_cliente
            OR t.date IS DISTINCT FROM s.date
            OR t.raw_date IS DISTINCT FROM s.raw_date
            OR t.product IS DISTINCT FROM s.product
            OR t.type IS DISTINCT FROM s.type
            OR t.raw_type IS DISTINCT FROM s.raw_type
            OR t.fund IS DISTINCT FROM s.fund
            OR t.amount IS DISTINCT FROM s.amount
            OR t.description IS DISTINCT FROM s.description
            OR t.commercial_name IS DISTINCT FROM s.commercial_name
        THEN 'ACTUALIZAR'
        ELSE 'OMITIR'
    END AS accion
FROM
    movimientos_dia_t1 AS s
FULL OUTER JOIN
    movimientos_dia_t AS t
ON
    t.business_key = s.business_key;
