-- Vistas temporales sobre la base producida por el pipeline.
-- No modifican las tablas de negocio. Las acciones corresponden a la última ejecución.
CREATE OR REPLACE TEMP VIEW analytics_cortes AS
SELECT
    'T' AS corte,
    *
FROM
    movimientos_dia_t
UNION ALL
SELECT
    'T1' AS corte,
    *
FROM
    movimientos_dia_t1;

CREATE OR REPLACE TEMP VIEW analytics_resumen AS
SELECT
    corte,
    COUNT(*) AS movimientos,
    COUNT(DISTINCT id_cliente) AS clientes,
    COUNT(*) FILTER (WHERE type = 'ENTRADA') AS entradas,
    COUNT(*) FILTER (WHERE type = 'SALIDA') AS salidas,
    COUNT(*) FILTER (WHERE amount IS NULL) AS montos_nulos,
    ROUND(100.0 * COUNT(*) FILTER (WHERE amount IS NULL) / COUNT(*), 2) AS porcentaje_montos_nulos,
    COUNT(*) FILTER (WHERE amount < 0) AS montos_negativos,
    COUNT(*) FILTER (WHERE amount = 0) AS montos_cero,
    COUNT(*) FILTER (WHERE date IS NULL) AS fechas_nulas,
    COUNT(*) FILTER (WHERE type IS NULL) AS tipos_nulos,
    COUNT(*) FILTER (WHERE business_key IS NULL) AS llaves_nulas,
    MIN(date) AS fecha_minima,
    MAX(date) AS fecha_maxima
FROM
    analytics_cortes
GROUP BY
    corte;

CREATE OR REPLACE TEMP VIEW analytics_duplicados AS
SELECT
    corte,
    COUNT(*) AS llaves_repetidas,
    SUM(filas) AS filas_con_llave_repetida,
    SUM(filas - 1) AS filas_excedentes
FROM (
    SELECT
        corte,
        business_key,
        COUNT(*) AS filas
    FROM
        analytics_cortes
    WHERE
        business_key IS NOT NULL
    GROUP BY
        corte,
        business_key
    HAVING
        COUNT(*) > 1
)
GROUP BY
    corte;

CREATE OR REPLACE TEMP VIEW analytics_flujos AS
SELECT
    corte,
    type,
    COUNT(*) AS movimientos,
    COUNT(amount) AS movimientos_con_monto,
    COUNT(*) FILTER (WHERE amount IS NULL) AS montos_nulos,
    COUNT(*) FILTER (WHERE amount < 0) AS montos_negativos,
    SUM(amount) AS suma_montos_disponibles
FROM
    analytics_cortes
GROUP BY
    corte, type;

CREATE OR REPLACE TEMP VIEW analytics_productos_fondos AS
SELECT
    corte,
    product,
    fund,
    type,
    COUNT(*) AS movimientos,
    COUNT(*) FILTER (WHERE amount IS NULL) AS montos_nulos,
    COUNT(*) FILTER (WHERE amount < 0) AS montos_negativos,
    SUM(amount) AS suma_montos_disponibles
FROM
    analytics_cortes
GROUP BY
    corte,
    product,
    fund,
    type;

CREATE OR REPLACE TEMP VIEW analytics_fechas AS
SELECT
    corte,
    date,
    type,
    COUNT(*) AS movimientos,
    COUNT(*) FILTER (WHERE amount IS NULL) AS montos_nulos,
    SUM(amount) AS suma_montos_disponibles
FROM
    analytics_cortes
GROUP BY
    corte,
    date,
    type;

CREATE OR REPLACE TEMP VIEW analytics_acciones AS
SELECT
    accion,
    COUNT(*) AS observaciones,
    COUNT(row_id_t) AS filas_t,
    COUNT(row_id_t1) AS filas_t1
FROM
    pipeline_logs
WHERE
    run_id = (SELECT MAX(run_id) FROM pipeline_ejecuciones)
GROUP BY
    accion;

CREATE OR REPLACE TEMP VIEW analytics_validacion AS
SELECT
    (SELECT COUNT(*) FROM movimientos_dia_t1) AS filas_t1,
    (SELECT COUNT(*) FROM movimientos_dia_final) AS filas_finales,
    (SELECT COUNT(*) FROM (
        (SELECT
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
         FROM movimientos_dia_t1
         EXCEPT ALL
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
         FROM movimientos_dia_final)
        UNION ALL
        (SELECT
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
         FROM movimientos_dia_final
         EXCEPT ALL
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
         FROM movimientos_dia_t1)
    )) AS diferencias_contenido,
    (SELECT COUNT(*) FROM movimientos_dia_t) AS filas_t,
    (SELECT COALESCE(SUM(filas_t), 0) FROM analytics_acciones) AS filas_t_clasificadas,
    (SELECT COALESCE(SUM(filas_t1), 0) FROM analytics_acciones) AS filas_t1_clasificadas;
