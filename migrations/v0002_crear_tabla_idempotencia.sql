CREATE SEQUENCE IF NOT EXISTS seq_idempotencia_archivo_movimientos START 1;

CREATE TABLE IF NOT EXISTS idempotencia_archivo_movimientos
(
    row_id BIGINT PRIMARY KEY DEFAULT NEXTVAL('seq_idempotencia_archivo_movimientos'),
    archivo_sha256 VARCHAR NOT NULL,
    nombre_archivo VARCHAR NOT NULL,
    fecha_aplicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear indices para la tabla idempotencia_archivo_movimientos
CREATE UNIQUE INDEX IF NOT EXISTS idx_idempotencia_archivo_movimientos_archivo_sha256 ON idempotencia_archivo_movimientos(archivo_sha256);
