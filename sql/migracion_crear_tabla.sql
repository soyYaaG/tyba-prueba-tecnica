CREATE TABLE IF NOT EXISTS migraciones
(
    version VARCHAR PRIMARY KEY,
    nombre_archivo VARCHAR NOT NULL,
    huella_sha256 VARCHAR NOT NULL,
    fecha_aplicacion TIMESTAMP NOT NULL
)
