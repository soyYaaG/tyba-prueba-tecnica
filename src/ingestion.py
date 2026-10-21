from pathlib import Path

from duckdb import DuckDBPyConnection

from sql import get_sql

from .core import config


def insert_movements(con: DuckDBPyConnection, file: Path):
    if not file.is_file():
        raise FileNotFoundError(file)

    table_name = file.stem.lower()

    con.execute('BEGIN TRANSACTION')
    try:
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
