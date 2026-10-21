SELECT
    archivo_sha256,
    nombre_archivo,
FROM
    idempotencia_archivo_movimientos
WHERE
    archivo_sha256 = '{hash}';
