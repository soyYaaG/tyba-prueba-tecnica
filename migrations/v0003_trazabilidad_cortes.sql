-- Crear tabla archivos_activos
CREATE TABLE archivos_activos
(
    tabla VARCHAR PRIMARY KEY,
    archivo_sha256 VARCHAR NOT NULL,
    nombre_archivo VARCHAR NOT NULL
);

-- Secuencia para la tabla pipeline_ejecuciones
CREATE SEQUENCE seq_pipeline_ejecuciones START 1;

-- Crear tabla pipeline_ejecuciones
CREATE TABLE pipeline_ejecuciones
(
    run_id BIGINT PRIMARY KEY DEFAULT NEXTVAL('seq_pipeline_ejecuciones'),
    hash_t VARCHAR NOT NULL,
    hash_t1 VARCHAR NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Modificar tabla pipeline_logs para incluir run_id, row_id_t y row_id_t1
ALTER TABLE pipeline_logs ADD COLUMN run_id BIGINT;
ALTER TABLE pipeline_logs ADD COLUMN row_id_t BIGINT;
ALTER TABLE pipeline_logs ADD COLUMN row_id_t1 BIGINT;
