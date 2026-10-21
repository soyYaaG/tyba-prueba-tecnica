from . import (
    MovementInsertResult,
    config,
    get_connection,
    insert_movements,
    process,
    run_migrations,
)


def run():
    with get_connection() as con:
        run_migrations()
        status = set()

        for snapshot in config.pipeline.snapshots:
            path = config.data.raw_directory / snapshot.file
            print(f'Obteniendo movimientos del archivo: {path}')
            result = insert_movements(con, path)
            print(f'Archivo {path} -> {result.value}')
            status.add(result.value)

        if MovementInsertResult.OMITIDO.value in status:
            print('Los archivos ya se encontraban cargados.')
            return

        print('Procesando movimientos...')
        process(con)
        print('Movimientos procesados exitosamente')


if __name__ == '__main__':
    run()
