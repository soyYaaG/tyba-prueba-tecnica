-- Insertar los datos de la tabla movimientos_dia_t1 en la tabla movimientos_dia_final
-- Solo se insertan los datos que no existen en la tabla movimientos_dia_final
INSERT INTO movimientos_dia_final
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
SELECT
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
FROM
    movimientos_dia_t1
WHERE
    business_key NOT IN
    (
        SELECT
            business_key
        FROM
            movimientos_dia_final
    );

-- Actualizar los datos de la tabla movimientos_dia_final con los datos de la tabla movimientos_dia_t1
-- Solo se actualizan los datos que existen en la tabla movimientos_dia_final y que tienen diferencias con la tabla movimientos_dia_t1.
-- Si existen datos en la tabla movimientos_dia_t1 que no existen en la tabla movimientos_dia_final, se insertan en la tabla movimientos_dia_final.
-- Si existen datos en la tabla movimientos_dia_final que no existen en la tabla movimientos_dia_t1, se eliminan de la tabla movimientos_dia_final.
MERGE INTO
    movimientos_dia_final AS t
USING
    movimientos_dia_t1 AS s
ON
    t.business_key = s.business_key
WHEN MATCHED AND
(
    t.id_cliente IS DISTINCT FROM s.id_cliente
    OR t.date IS DISTINCT FROM s.date
    OR t.raw_date IS DISTINCT FROM s.raw_date
    OR t.product IS DISTINCT FROM s.product
    OR t.type IS DISTINCT FROM s.type
    OR t.raw_type IS DISTINCT FROM s.raw_type
    OR t.fund IS DISTINCT FROM s.fund
    OR t.amount IS DISTINCT FROM s.amount
    OR t.description IS DISTINCT FROM s.description
    OR t.commercial_name IS DISTINCT FROM s.commercial_name
    OR t.row_hash IS DISTINCT FROM s.row_hash
) THEN UPDATE SET
    row_id_t1 = s.row_id,
    id_cliente = s.id_cliente,
    date = s.date,
    raw_date = s.raw_date,
    product = s.product,
    type = s.type,
    raw_type = s.raw_type,
    fund = s.fund,
    amount = s.amount,
    description = s.description,
    commercial_name = s.commercial_name,
    row_hash = s.row_hash
WHEN NOT MATCHED BY SOURCE THEN DELETE
WHEN NOT MATCHED BY TARGET THEN INSERT
(
    row_id_t1,
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
VALUES
(
    s.row_id,
    s.id_cliente,
    s.date,
    s.raw_date,
    s.product,
    s.type,
    s.raw_type,
    s.fund,
    s.amount,
    s.description,
    s.commercial_name,
    s.business_key,
    s.row_hash
);
