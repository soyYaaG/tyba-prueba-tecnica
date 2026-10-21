-- Crear secuencias para la tabla movimientos_dia_t
CREATE SEQUENCE IF NOT EXISTS seq_movimientos_dia_t START 1;

-- Crear tabla movimientos_dia_t
CREATE TABLE IF NOT EXISTS movimientos_dia_t
(
    row_id BIGINT PRIMARY KEY DEFAULT NEXTVAL('seq_movimientos_dia_t'),
    id_cliente VARCHAR,
    date DATE,
    raw_date VARCHAR,
    product VARCHAR,
    type VARCHAR,
    raw_type VARCHAR,
    fund VARCHAR,
    amount DECIMAL(20,4),
    description VARCHAR,
    commercial_name VARCHAR,
    business_key VARCHAR,
    row_hash VARCHAR NOT NULL,
);

--Crear indices para la tabla movimientos_dia_t
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t_id_cliente ON movimientos_dia_t(id_cliente);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t_product ON movimientos_dia_t(product);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t_type ON movimientos_dia_t(type);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t_business_key ON movimientos_dia_t(business_key);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t_row_hash ON movimientos_dia_t(row_hash);


-- Crear secuencias para la tabla movimientos_dia_t1
CREATE SEQUENCE IF NOT EXISTS seq_movimientos_dia_t1 START 1;

-- Crear tabla movimientos_dia_t1
CREATE TABLE IF NOT EXISTS movimientos_dia_t1
(
    row_id BIGINT PRIMARY KEY DEFAULT NEXTVAL('seq_movimientos_dia_t1'),
    id_cliente VARCHAR,
    date DATE,
    raw_date VARCHAR,
    product VARCHAR,
    type VARCHAR,
    raw_type VARCHAR,
    fund VARCHAR,
    amount DECIMAL(20,4),
    description VARCHAR,
    commercial_name VARCHAR,
    business_key VARCHAR,
    row_hash VARCHAR NOT NULL,
);

-- Crear indices para la tabla movimientos_dia_t1
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t1_id_cliente ON movimientos_dia_t1(id_cliente);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t1_product ON movimientos_dia_t1(product);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t1_type ON movimientos_dia_t1(type);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t1_business_key ON movimientos_dia_t1(business_key);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_t1_row_hash ON movimientos_dia_t1(row_hash);


-- Crer secuencia para la tabla tipos_movimientos
CREATE SEQUENCE IF NOT EXISTS seq_tipos_movimientos START 1;

-- Crear tabla tipos_movimientos
CREATE TABLE IF NOT EXISTS tipos_movimientos
(
    row_id INTEGER PRIMARY KEY DEFAULT NEXTVAL('seq_tipos_movimientos'),
    tipo VARCHAR,
    raw_tipo VARCHAR,
    UNIQUE(tipo, raw_tipo)
);

-- Insertar datos en la tabla tipos_movimientos
INSERT INTO tipos_movimientos (tipo, raw_tipo)
VALUES ('ENTRADA', 'ENTRADA'),
('SALIDA', 'SALIDA'),
('ENTRADA', 'IN'),
('SALIDA', 'OUT')
ON CONFLICT (tipo, raw_tipo) DO NOTHING;


-- Crear secuencias para la tabla movimientos_dia_final
CREATE SEQUENCE IF NOT EXISTS seq_movimientos_dia_final START 1;

-- Crear tabla movimientos_dia_t
CREATE TABLE IF NOT EXISTS movimientos_dia_final
(
    row_id BIGINT PRIMARY KEY DEFAULT NEXTVAL('seq_movimientos_dia_final'),
    row_id_t1 BIGINT,
    id_cliente VARCHAR,
    date DATE,
    raw_date VARCHAR,
    product VARCHAR,
    type VARCHAR,
    raw_type VARCHAR,
    fund VARCHAR,
    amount DECIMAL(20,4),
    description VARCHAR,
    commercial_name VARCHAR,
    business_key VARCHAR,
    row_hash VARCHAR NOT NULL,
);

--Crear indices para la tabla movimientos_dia_final
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_final_row_id_t1 ON movimientos_dia_final(row_id_t1);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_final_id_cliente ON movimientos_dia_final(id_cliente);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_final_product ON movimientos_dia_final(product);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_final_type ON movimientos_dia_final(type);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_final_business_key ON movimientos_dia_final(business_key);
CREATE INDEX IF NOT EXISTS idx_movimientos_dia_final_row_hash ON movimientos_dia_final(row_hash);


-- Crear tabla de pipeline_logs
CREATE SEQUENCE IF NOT EXISTS seq_pipeline_logs START 1;

CREATE TABLE IF NOT EXISTS pipeline_logs
(
    row_id BIGINT PRIMARY KEY DEFAULT NEXTVAL('seq_pipeline_logs'),
    accion VARCHAR,
    business_key VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear indices para la tabla pipeline_logs
CREATE INDEX IF NOT EXISTS idx_pipeline_logs_accion ON pipeline_logs(accion);
CREATE INDEX IF NOT EXISTS idx_pipeline_logs_business_key ON pipeline_logs(business_key);
