from duckdb import DuckDBPyConnection, connect

from .config import config


def get_connection() -> DuckDBPyConnection:
    db_path = config.database.path
    db_path.parent.mkdir(parents=True, exist_ok=True)

    return connect(db_path)
