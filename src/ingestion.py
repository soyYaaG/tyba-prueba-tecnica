import hashlib
from enum import StrEnum
from pathlib import Path

from duckdb import DuckDBPyConnection

from sql import get_sql

from .core import config


class MovementInsertResult(StrEnum):
    OMITIDO = 'omitido'
    INSERTADO = 'insertado'


def insert_movements(con: DuckDBPyConnection, file: Path) -> MovementInsertResult:
    if not file.is_file():
        raise FileNotFoundError(file)

    table_name = file.stem.lower()
    file_hash = __file_sha256(file)

    existing = con.execute(
        get_sql(config.data.sql_directory, 'idempotencia_verificar').format(
            hash=file_hash
        )
    ).fetchone()

    if existing:
        return MovementInsertResult.OMITIDO

    con.execute('BEGIN TRANSACTION')
    try:
        sql_query = get_sql(config.data.sql_directory, 'idempotencia_insertar')
        con.execute(sql_query.format(hash=file_hash, nombre_archivo=file.name))

        sql_query = get_sql(config.data.sql_directory, 'movimientos_insertar')
        con.execute(
            sql_query.format(
                table_name=table_name, file=str(file.resolve()).replace("'", "''")
            )
        )
    except Exception as e:
        con.execute('ROLLBACK')
        raise e
    else:
        con.execute('COMMIT')
        return MovementInsertResult.INSERTADO


def __file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()
