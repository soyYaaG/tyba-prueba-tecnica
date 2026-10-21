from functools import cache
from pathlib import Path

__all__ = ['get_sql']

_SQL_FILES = {
    'migracion_crear_tabla': 'migracion_crear_tabla.sql',
    'migracion_insertar': 'migracion_insertar.sql',
    'migracion_seleccionar_huella_sha256': 'migracion_seleccionar_huella_sha256.sql',
    'movimientos_insertar': 'movimientos_insertar.sql',
    'movimiento_merge': 'movimiento_merge.sql',
    'pipeline_logs_insertar': 'pipeline_logs_insertar.sql',
    'idempotencia_insertar': 'idempotencia_insertar.sql',
    'idempotencia_verificar': 'idempotencia_verificar.sql',
}


@cache
def get_sql(sql_directory: Path, name: str) -> str:
    try:
        filename = _SQL_FILES[name]
    except KeyError:
        raise ValueError(
            f"Archivo SQL no encontrado: '{name}'. Disponibles: {', '.join(_SQL_FILES)}"
        ) from None
    return (sql_directory / filename).read_text(encoding='utf-8')
