import hashlib
from enum import StrEnum
from pathlib import Path

from duckdb import DuckDBPyConnection

from sql import get_sql

from .core import config


class MovementInsertResult(StrEnum):
    OMITIDO = 'omitido'
    INSERTADO = 'insertado'


def insert_movements(
    con: DuckDBPyConnection, file: Path, *, manage_transaction: bool = True
) -> MovementInsertResult:
    if not file.is_file():
        raise FileNotFoundError(file)

    table_name = file.stem.lower()
    if table_name not in {'movimientos_dia_t', 'movimientos_dia_t1'}:
        raise ValueError(f'Archivo de corte no soportado: {file.name}')
    file_hash = __file_sha256(file)

    existing = con.execute(
        'SELECT 1 FROM archivos_activos WHERE tabla = ? AND archivo_sha256 = ?',
        [table_name, file_hash],
    ).fetchone()

    if existing:
        return MovementInsertResult.OMITIDO

    if manage_transaction:
        con.execute('BEGIN TRANSACTION')
    try:
        # Cada tabla representa un único corte vigente, no un historial acumulado.
        con.execute(f'DELETE FROM {table_name}')

        sql_query = get_sql(config.data.sql_directory, 'movimientos_insertar')
        con.execute(
            sql_query.format(
                table_name=table_name, file=str(file.resolve()).replace("'", "''")
            )
        )
        con.execute(
            """INSERT INTO idempotencia_archivo_movimientos
               (archivo_sha256, nombre_archivo) VALUES (?, ?)
               ON CONFLICT DO NOTHING""",
            [file_hash, file.name],
        )
        con.execute(
            """INSERT INTO archivos_activos VALUES (?, ?, ?)
               ON CONFLICT (tabla) DO UPDATE SET
               archivo_sha256 = excluded.archivo_sha256,
               nombre_archivo = excluded.nombre_archivo""",
            [table_name, file_hash, file.name],
        )
    except Exception:
        if manage_transaction:
            con.execute('ROLLBACK')
        raise
    else:
        if manage_transaction:
            con.execute('COMMIT')
        return MovementInsertResult.INSERTADO


def __file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()
