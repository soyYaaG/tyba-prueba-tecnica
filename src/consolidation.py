from duckdb import DuckDBPyConnection

from sql import get_sql

from .core import config


def process(con: DuckDBPyConnection):
    con.execute('BEGIN TRANSACTION')
    try:
        con.execute(
            get_sql(config.data.sql_directory, 'movimiento_pipeline_logs_insertar')
        )
        con.execute(get_sql(config.data.sql_directory, 'movimiento_merge'))
    except Exception as e:
        con.execute('ROLLBACK')
        raise e
    else:
        con.execute('COMMIT')
