# Prueba técnica Tyba

Esta solución compara dos cortes de movimientos financieros, normaliza los datos y mantiene una base DuckDB con el estado del segundo corte. También registra los cambios identificados y genera reportes para revisar la calidad y el comportamiento de los datos.

El análisis de los archivos entregados está en [INSIGHTS.md](INSIGHTS.md). Allí se presentan los principales hallazgos, sus implicaciones y las recomendaciones para una operación diaria.

## 1. Ejecución rápida con Docker

Necesitas Docker con Docker Compose y el motor en ejecución. Los archivos de entrada deben estar en estas rutas:

```text
data/raw/movimientos_dia_T.parquet
data/raw/movimientos_dia_T1.parquet
```

Desde la raíz del repositorio, ejecuta:

```bash
docker compose up --build
```

El comando construye la imagen y ejecuta el proceso completo. Al terminar, encontrarás en `data/output/`:

- `tyba.duckdb`: base de datos con los movimientos y el registro de cambios.
- `insights.md`: reporte con las métricas de los cortes procesados.
- `analytics_*.csv`: resultados agregados para consultar o analizar en otras herramientas.

La carpeta `data/` se comparte con el contenedor, por lo que los resultados permanecen en tu equipo cuando este termina. Si cambias el código, la configuración o las consultas, vuelve a ejecutar el comando con `--build`.

También puedes construir la imagen con `docker compose build` y ejecutar `docker compose run --rm pipeline`. Esta alternativa elimina el contenedor al finalizar y conserva los resultados en la carpeta compartida.

## 2. Ejecución local

Necesitas Python 3.14 y `uv`. Desde la raíz del repositorio:

```bash
uv sync --frozen
uv run --frozen python main.py
```

`uv sync` prepara el entorno `.venv` con las versiones registradas en `uv.lock`. No necesitas activar el entorno ni ejecutar las migraciones por separado.

Para aplicar únicamente las migraciones:

```bash
uv run --frozen python -m src.core
```

## 3. Estructura del proyecto

```text
.
├── main.py                  # Inicio del proceso
├── config/
│   └── settings.toml        # Rutas y archivos de entrada
├── data/
│   ├── raw/                 # Archivos Parquet originales
│   └── output/              # Base de datos y reportes generados
├── migrations/              # Cambios versionados del esquema de datos
├── sql/                     # Consultas de carga, comparación y analítica
├── src/
│   ├── pipeline.py          # Coordinación del proceso completo
│   ├── ingestion.py         # Carga y control de archivos procesados
│   ├── consolidation.py     # Registro de cambios y actualización del resultado
│   ├── analytics.py         # Generación de reportes y CSV
│   └── core/
│       ├── config.py        # Lectura y validación de la configuración
│       ├── database.py      # Conexión a DuckDB
│       ├── migrate.py       # Aplicación de migraciones
│       └── __main__.py      # Ejecución independiente de migraciones
├── INSIGHTS.md              # Hallazgos y recomendaciones
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml           # Dependencias y herramientas
├── uv.lock                  # Versiones de las dependencias
└── README.md
```

La solución utiliza **Python** para coordinar el proceso y **DuckDB** para leer Parquet, transformar datos y consolidar resultados mediante SQL. La configuración se define en **TOML**, se lee con `tomllib` y se valida con **Pydantic**. Las dependencias se administran con **uv**.

## 4. Cómo funciona

1. **Prepara la base de datos.** Aplica las migraciones pendientes y verifica que las ya ejecutadas conserven su contenido mediante SHA-256.
2. **Carga los cortes vigentes.** Compara la huella de cada archivo con la de su tabla activa. Si cambió, reemplaza ese corte; si permanece igual, omite la carga.
3. **Normaliza los datos.** Unifica fechas y tipos de movimiento, convierte los montos a `DECIMAL(20,4)` y conserva los valores originales de fecha y tipo.
4. **Compara los movimientos.** Calcula una llave compuesta (`business_key`) para identificar correspondencias y una huella del contenido (`row_hash`) para detectar cambios.
5. **Consolida el resultado.** Actualiza `movimientos_dia_final` con el contenido de T1 y registra las acciones de la comparación. La carga, los logs y la consolidación se confirman en una sola transacción.
6. **Genera la analítica.** Exporta un reporte Markdown y siete CSV con métricas de volumen, calidad, montos y cambios entre cortes.

La comparación distingue `INSERTAR`, `ACTUALIZAR`, `ELIMINAR` y `OMITIR` cuando la llave permite una correspondencia única. Si la llave se repite en cualquiera de los cortes, las filas involucradas se reportan como `AMBIGUO`. Las filas sin llave se reportan como `SIN_LLAVE`.

Todos los registros de T1 se conservan en el resultado. Las llaves únicas se procesan con `MERGE`; las filas con llave repetida o nula se reemplazan como conjunto. Un cambio exclusivamente de formato, una vez normalizado, se considera equivalente.

## 5. Configuración y datos de entrada

Las rutas se definen en `config/settings.toml`:

```toml
[database]
path = "data/output/tyba.duckdb"

[migrations]
directory = "migrations"

[data]
raw_directory = "data/raw"
output_directory = "data/output"
sql_directory = "sql"

[pipeline]
snapshots = [
    { batch = "T", file = "movimientos_dia_T.parquet" },
    { batch = "T1", file = "movimientos_dia_T1.parquet" },
]
```

Los Parquet deben incluir `id_cliente`, `date`, `product`, `type`, `fund`, `amount`, `description` y `commercial_name`.

Ejecuta los comandos desde la raíz del repositorio para resolver correctamente las rutas relativas. `database.path` define dónde se guarda DuckDB y `data.output_directory` define la carpeta de los reportes.

Los nombres de archivo determinan las tablas de entrada. La solución espera exactamente un archivo `movimientos_dia_T.parquet` y uno `movimientos_dia_T1.parquet`; para admitir otros nombres o más cortes, también se deben ajustar la validación y las consultas SQL. El campo `batch` es descriptivo y no selecciona la tabla de destino.

## 6. Resultados y analítica

### Base de datos

| Tabla | Para qué sirve |
| --- | --- |
| `movimientos_dia_t` | Consultar el primer corte normalizado. |
| `movimientos_dia_t1` | Consultar el segundo corte normalizado. |
| `movimientos_dia_final` | Consultar el estado consolidado de T1. |
| `pipeline_logs` | Revisar las acciones identificadas en cada ejecución. |
| `tipos_movimientos` | Consultar las equivalencias entre tipos originales y normalizados. |
| `idempotencia_archivo_movimientos` | Identificar los archivos que se han cargado. |
| `archivos_activos` | Saber qué archivo representa cada tabla de entrada. |
| `pipeline_ejecuciones` | Consultar las huellas de los cortes y la fecha de cada consolidación. |
| `migraciones` | Revisar los cambios de esquema aplicados. |

Desde un cliente compatible con DuckDB puedes consultar:

```sql
-- Acciones de la última ejecución
SELECT accion, COUNT(*) AS total
FROM pipeline_logs
WHERE run_id = (SELECT MAX(run_id) FROM pipeline_ejecuciones)
GROUP BY accion
ORDER BY accion;

-- Cantidad de movimientos consolidados
SELECT COUNT(*) AS total_movimientos
FROM movimientos_dia_final;

-- Muestra de los datos
SELECT * FROM movimientos_dia_final LIMIT 10;
```

### Reportes

| Archivo en `data/output/` | Contenido |
| --- | --- |
| `insights.md` | Resumen de las métricas de los cortes vigentes. |
| `analytics_resumen.csv` | Movimientos, clientes, calidad de datos y fechas por corte. |
| `analytics_duplicados.csv` | Llaves repetidas y cantidad de filas involucradas. |
| `analytics_flujos.csv` | Cantidades y montos disponibles por tipo de movimiento. |
| `analytics_productos_fondos.csv` | Distribución por producto, fondo y tipo. |
| `analytics_fechas.csv` | Distribución por fecha del movimiento y tipo. |
| `analytics_acciones.csv` | Acciones de la última ejecución y filas involucradas. |
| `analytics_validacion.csv` | Comparación del resultado con T1 y cobertura de la clasificación. |

Para regenerar los reportes de una base ya procesada:

```bash
uv run --frozen python -m src.analytics
```

Con Docker, después de construir la imagen:

```bash
docker compose run --rm pipeline uv run python -m src.analytics
```

Las consultas están en `sql/analytics.sql`. Crean vistas temporales que puedes consultar en la misma conexión, por ejemplo: `SELECT * FROM analytics_resumen ORDER BY corte;`.

Las sumas excluyen montos nulos y conservan los signos originales. Para interpretarlas se debe considerar la cobertura de datos y confirmar la moneda. Las categorías `AMBIGUO` y `SIN_LLAVE` cuentan las filas de cada corte por separado.

## Observaciones Calidad de datos

1. **Identificador de transacción ausente.** Los archivos recibidos no incluyen el campo `ID` mencionado en el enunciado. `id_cliente` identifica al cliente, pero no permite distinguir cada uno de sus movimientos. Los `row_id` generados por DuckDB son identificadores internos.
2. **Fechas con formatos diferentes.** Se identificaron fechas en `DD/MM/AAAA` y `AAAA-MM-DD`. Elegí unificar su representación como `AAAA-MM-DD` y almacenarlas como `DATE`. La implementación también admite `AAAA/MM/DD` y `DD-MM-AAAA`. Los valores vacíos o inválidos quedan como `NULL`; el dato original se conserva en `raw_date`.
3. **Tipos de movimiento sin un formato uniforme.** Normalicé el campo `type` a `ENTRADA` y `SALIDA`, incluyendo las equivalencias `IN` y `OUT`. Antes de buscar la equivalencia se eliminan espacios en los extremos y acentos, y se convierte el texto a mayúsculas. Los valores no reconocidos quedan como `NULL`, con el original disponible en `raw_type`.
4. **Llave compuesta como criterio de comparación.** Para avanzar sin un identificador de transacción, utilicé `(id_cliente, date, product, type, fund, commercial_name)`. Su representación SHA-256 se guarda en `business_key`. Esta decisión permite comparar los cortes, aunque movimientos distintos pueden compartir la misma llave. Además, cambiar uno de sus componentes puede interpretarse como una eliminación y una inserción. La definición está centralizada en `sql/movimientos_insertar.sql` para facilitar su ajuste cuando se disponga de un mejor criterio.

Los hashes se calculan sobre los campos ya normalizados. Los montos que no pueden convertirse a `DECIMAL(20,4)` quedan como `NULL`. Si falta un cliente válido, una fecha válida o un tipo reconocido, no se genera la llave: la fila se conserva y se reporta como `SIN_LLAVE`. Las llaves repetidas se reportan como `AMBIGUO`.

Cubren los cambios entre cortes, reejecuciones, modificaciones de un solo archivo, restauración de cortes anteriores, llaves repetidas o nulas, cambios de formato, cortes vacíos y recuperación ante fallas.

## 7. Reejecución, trazabilidad y alcance

- **Mismos archivos:** se omiten la carga y la consolidación, sin duplicar movimientos ni logs. Los reportes se regeneran.
- **Un archivo cambia:** se reemplaza su tabla y se compara la pareja vigente. Una falla antes de confirmar la transacción revierte también las cargas y sus registros de control.
- **Trazabilidad:** cada consolidación guarda las huellas de ambos archivos. Los logs conservan la ejecución, la acción y los identificadores internos de las filas comparadas. Los logs anteriores a la migración de trazabilidad tienen `run_id` nulo y se excluyen del reporte de la última ejecución.
- **Historial:** las tablas de entrada y los CSV muestran los cortes vigentes. Para conservar el contenido completo de cortes anteriores se necesita una política adicional de almacenamiento histórico.
- **Escala:** el trabajo sobre los movimientos se ejecuta en DuckDB mediante SQL, sin cargar todas las filas en listas de Python. La comparación recorre los cortes completos y asume un único proceso escritor. Queda pendiente medir el rendimiento con millones de filas.

Para repetir la prueba en una base nueva y conservar los resultados anteriores, cambia `database.path`. Si usas Docker, reconstruye la imagen después del cambio.

Para modificar el esquema, agrega una migración con el patrón `vNNNN_descripcion.sql`, una versión única y ceros a la izquierda. Las migraciones ya aplicadas se verifican mediante SHA-256; editarlas detendrá la ejecución.
