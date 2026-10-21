DELETE
FROM movimientos_dia_final
WHERE
    business_key IS NULL
    OR business_key IN (
        SELECT
            business_key
        FROM
            movimientos_dia_final
        GROUP BY
            business_key
        HAVING
            COUNT(*) > 1
    )
    OR business_key IN (
        SELECT
            business_key
        FROM
            movimientos_dia_t1
        WHERE
            business_key IS NOT NULL
        GROUP BY
            business_key HAVING COUNT(*) > 1
    );

MERGE INTO movimientos_dia_final AS t
USING
(
    SELECT
        *
    FROM
        movimientos_dia_t1
    WHERE
        business_key IS NOT NULL
    QUALIFY
        COUNT(*) OVER (PARTITION BY business_key) = 1
) AS s
ON
    t.business_key = s.business_key
WHEN MATCHED THEN UPDATE SET
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
) VALUES (
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

INSERT INTO movimientos_dia_final (
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
SELECT
    row_id,
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
    business_key IS NULL
    OR business_key IN (
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
    );
