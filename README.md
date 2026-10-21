# Prueba técnica Tyba

Pipeline de datos que carga dos archivos Parquet de movimientos (`T` y `T1`), normaliza sus campos y compara ambos conjuntos para identificar inserciones, actualizaciones, eliminaciones y movimientos sin cambios. El resultado se almacena en una base de datos DuckDB local.

## Tecnologías

- **Python 3.14:** orquestación del pipeline.
- **uv:** gestión del entorno y de las dependencias, con versiones registradas en `uv.lock`.
- **DuckDB:** lectura de archivos Parquet, transformaciones SQL y almacenamiento de resultados.
- **TOML y `tomllib`:** configuración mediante la biblioteca estándar de Python.
- **Pydantic:** validación de la estructura de configuración.
- **Docker y Docker Compose:** ejecución en un contenedor.

## Estructura del proyecto

```text
.
├── main.py                  # Punto de entrada del pipeline
├── config/
│   └── settings.toml        # Rutas y archivos de entrada
├── data/
│   ├── raw/                 # Archivos Parquet originales
│   └── output/              # Base de datos generada al ejecutar
├── migrations/              # Migraciones SQL versionadas
├── sql/                     # Consultas de carga, comparación y consolidación
├── src/
│   ├── pipeline.py          # Orquestación de migraciones, carga y consolidación
│   ├── ingestion.py         # Carga de archivos y control de idempotencia
│   ├── consolidation.py     # Ejecución transaccional del registro y consolidación
│   └── core/
│       ├── config.py        # Lectura y validación de settings.toml
│       ├── database.py      # Conexión a DuckDB
│       ├── migrate.py       # Aplicación y verificación de migraciones
│       └── __main__.py      # Punto de entrada para ejecutar solo migraciones
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml           # Dependencias y configuración de herramientas
├── uv.lock                  # Versiones resueltas de dependencias
└── README.md
```

## Archivos de entrada

Los archivos deben estar en `data/raw/` con estos nombres:

```text
data/raw/movimientos_dia_T.parquet
data/raw/movimientos_dia_T1.parquet
```

La consulta de carga espera las columnas `id_cliente`, `date`, `product`, `type`, `fund`, `amount`, `description` y `commercial_name`.

## Ejecución local con uv

Requisitos: Python 3.14 y `uv` disponibles en el equipo. Ejecuta los comandos desde la raíz del repositorio:

```bash
uv sync --frozen
uv run --frozen python main.py
```

El primer comando prepara el entorno `.venv` e instala las dependencias del archivo de bloqueo. El segundo ejecuta el pipeline completo y crea `data/output/tyba.duckdb`. No es necesario activar manualmente el entorno virtual ni ejecutar las migraciones por separado.

Para aplicar únicamente las migraciones:

```bash
uv run --frozen python -m src.core
```

## Ejecución con Docker Compose

Requisito: Docker con Docker Compose disponible y el motor de Docker en ejecución. Los archivos de entrada también deben existir en `data/raw/`.

Desde la raíz del repositorio:

```bash
docker compose build
docker compose run --rm pipeline
```

La imagen incluye Python y `uv`, por lo que no necesitas instalarlos en el equipo para esta alternativa. El servicio monta `./data` en `/app/data`: lee los Parquet del equipo y guarda la base de datos en `data/output/tyba.duckdb`. El contenedor termina cuando finaliza el proceso.

Si modificas el código, las consultas SQL o la configuración, vuelve a construir la imagen antes de ejecutar.

## Configuración

Las rutas y los archivos de entrada se definen en `config/settings.toml`:

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

Las rutas relativas se resuelven desde el directorio de ejecución; por eso los comandos deben ejecutarse desde la raíz. La ubicación efectiva de la base de datos depende de `database.path`; cambiar solo `data.output_directory` no cambia esa ubicación.

Actualmente, el nombre de cada archivo determina su tabla de carga y las consultas SQL utilizan explícitamente `movimientos_dia_t` y `movimientos_dia_t1`. Cambiar los nombres de archivo o agregar otros conjuntos requiere adaptar también las tablas y las consultas; el campo `batch` no selecciona la tabla de destino.

## Flujo de procesamiento

1. **Migraciones:** crea las tablas y registra las versiones aplicadas. Verifica su huella SHA-256 para detectar cambios en migraciones ya ejecutadas.
2. **Carga:** calcula el SHA-256 de cada archivo y omite los archivos cuyo contenido ya está registrado. La carga de cada archivo se realiza dentro de una transacción.
3. **Normalización:** convierte fechas, homologa tipos de movimiento y convierte montos a `DECIMAL(20,4)`. Conserva los valores originales de fecha y tipo en `raw_date` y `raw_type`.
4. **Identificación:** calcula `business_key` a partir de la llave compuesta y `row_hash` a partir del contenido del movimiento.
5. **Comparación:** registra en `pipeline_logs` las acciones `INSERTAR`, `ACTUALIZAR`, `ELIMINAR` y `OMITIR`, comparando `T` con `T1`.
6. **Consolidación:** sincroniza `movimientos_dia_final` con `T1` mediante inserciones, actualizaciones y eliminaciones. El registro de acciones y la consolidación se ejecutan en una misma transacción.

## Resultados y consultas

La ejecución genera una base de datos en `data/output/tyba.duckdb`. Los resultados permanecen en DuckDB; el pipeline no exporta un archivo Parquet final.

| Tabla | Contenido |
| --- | --- |
| `movimientos_dia_t` | Movimientos normalizados del archivo T. |
| `movimientos_dia_t1` | Movimientos normalizados del archivo T1. |
| `movimientos_dia_final` | Movimientos consolidados tomando T1 como referencia. |
| `pipeline_logs` | Acciones identificadas al comparar T con T1. |
| `tipos_movimientos` | Equivalencias para normalizar los tipos de movimiento. |
| `idempotencia_archivo_movimientos` | Archivos cargados y sus huellas SHA-256. |
| `migraciones` | Versiones aplicadas y sus huellas SHA-256. |

Para consultar el resumen de acciones desde la terminal:

```bash
uv run --frozen python -c "import duckdb; con = duckdb.connect('data/output/tyba.duckdb', read_only=True); print(con.sql('SELECT accion, COUNT(*) AS total FROM pipeline_logs GROUP BY accion ORDER BY accion')); con.close()"
```

También puedes abrir la base de datos con un cliente compatible con DuckDB y ejecutar:

```sql
SELECT accion, COUNT(*) AS total
FROM pipeline_logs
GROUP BY accion
ORDER BY accion;

SELECT COUNT(*) AS total_movimientos
FROM movimientos_dia_final;

SELECT *
FROM movimientos_dia_final
LIMIT 10;
```

## Observaciones Calidad de datos

1. **Ausencia del identificador de transacción.** En los archivos recibidos no existe el campo `ID` que permita identificar de forma única cada transacción. El campo `id_cliente` identifica al cliente, pero no a cada uno de sus movimientos. Los identificadores `row_id` generados en DuckDB son internos y no sustituyen un identificador de transacción de origen.
2. **Normalización de fechas.** Se identifican fechas en los formatos `DD/MM/AAAA` y `AAAA-MM-DD`. Se decide unificar su representación como `AAAA-MM-DD`, almacenándolas como valores de tipo `DATE`. La implementación también admite `AAAA/MM/DD` y `DD-MM-AAAA`. Las fechas vacías, inválidas o no reconocidas quedan como `NULL`, y el valor original se conserva en `raw_date`.
3. **Normalización del tipo de movimiento.** Se decide utilizar únicamente los valores `ENTRADA` y `SALIDA`. Las equivalencias incluyen `IN` → `ENTRADA` y `OUT` → `SALIDA`; antes de buscar la equivalencia se eliminan espacios en los extremos y acentos, y se convierte el texto a mayúsculas. Los valores no reconocidos quedan como `NULL`, conservando el dato original en `raw_type`.
4. **Llave compuesta para comparar movimientos.** Al no disponer de un identificador único de transacción, no es posible garantizar la correspondencia individual de todos los movimientos entre archivos. Para avanzar con la prueba, se adopta la llave compuesta `(id_cliente, date, product, type, fund, commercial_name)`, representada mediante un hash SHA-256 en `business_key`. Esta decisión permite comparar movimientos bajo ese supuesto, pero dos transacciones distintas con los mismos valores compartirán la llave. Además, modificar cualquiera de esos campos puede interpretarse como una eliminación y una inserción, en lugar de una actualización. La definición está centralizada en `sql/movimientos_insertar.sql`, en el cálculo de `business_key`, para facilitar su ajuste si se dispone de un mejor criterio de identificación.

Adicionalmente, los montos que no pueden convertirse a `DECIMAL(20,4)` quedan como `NULL`. Si falta un `id_cliente` válido, una fecha válida o un tipo reconocido, no se genera `business_key`. Estos registros no se descartan automáticamente ni se separan en una tabla de rechazos, por lo que deben considerarse al interpretar la comparación.

## Reejecución y alcance

- Si vuelves a ejecutar los mismos archivos, su SHA-256 permite omitir la carga y el pipeline informa que ya estaban cargados.
- En la implementación actual, basta con que **uno** de los archivos sea omitido para que no se ejecute la comparación ni la consolidación. Las tablas de entrada, además, acumulan cargas de archivos con contenido nuevo. El flujo está orientado a procesar la pareja de archivos de esta prueba sobre una base nueva.
- Para repetir la prueba desde cero sin perder resultados anteriores, configura otra ruta de base de datos en `database.path` y ejecuta nuevamente. Si usas Docker, reconstruye la imagen para incorporar el cambio de configuración.
- Para evolucionar el esquema, agrega una nueva migración con el patrón `vNNNN_descripcion.sql`, una versión única y numeración con ceros a la izquierda. Evita editar migraciones ya aplicadas: la verificación SHA-256 detectará la modificación y detendrá la ejecución.
