from . import (
    config,
    get_connection,
    insert_movements,
    process,
    run_migrations,
)


def run():
    from .analytics import export_analytics

    run_migrations()
    with get_connection() as con:
        files = [
            config.data.raw_directory / snapshot.file
            for snapshot in config.pipeline.snapshots
        ]
        if sorted(file.stem.lower() for file in files) != [
            'movimientos_dia_t',
            'movimientos_dia_t1',
        ]:
            raise ValueError('Se requiere exactamente un corte T y un corte T1.')

        # Carga y consolidación se confirman juntas: una falla permite reintentar.
        con.execute('BEGIN TRANSACTION')
        try:
            for path in files:
                result = insert_movements(con, path, manage_transaction=False)
                print(f'Archivo {path} -> {result.value}')
            processed = process(con, manage_transaction=False)
            con.execute('COMMIT')
        except Exception:
            con.execute('ROLLBACK')
            raise
        print(
            'Movimientos procesados exitosamente'
            if processed
            else 'Los cortes ya estaban consolidados.'
        )
        export_analytics(con)


if __name__ == '__main__':
    run()
