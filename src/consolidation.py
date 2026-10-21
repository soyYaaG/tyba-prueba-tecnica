from duckdb import DuckDBPyConnection

from sql import get_sql

from .core import config


def process(con: DuckDBPyConnection, *, manage_transaction: bool = True) -> bool:
    if manage_transaction:
        con.execute('BEGIN TRANSACTION')
    try:
        hashes = dict(
            con.execute('SELECT tabla, archivo_sha256 FROM archivos_activos').fetchall()
        )
        pair = (hashes['movimientos_dia_t'], hashes['movimientos_dia_t1'])
        previous = con.execute(
            'SELECT hash_t, hash_t1 FROM pipeline_ejecuciones ORDER BY run_id DESC LIMIT 1'
        ).fetchone()
        if previous == pair:
            if manage_transaction:
                con.execute('COMMIT')
            return False

        run_id = con.execute(
            'INSERT INTO pipeline_ejecuciones (hash_t, hash_t1) VALUES (?, ?) RETURNING run_id',
            pair,
        ).fetchone()[0]
        con.execute(
            get_sql(config.data.sql_directory, 'pipeline_logs_insertar'), [run_id]
        )
        con.execute(get_sql(config.data.sql_directory, 'movimiento_merge'))
    except Exception:
        if manage_transaction:
            con.execute('ROLLBACK')
        raise
    else:
        if manage_transaction:
            con.execute('COMMIT')
        return True
