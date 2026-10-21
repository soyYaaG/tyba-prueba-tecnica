from . import config, get_connection, insert_movements, process, run_migrations


def run():
    with get_connection() as con:
        run_migrations()

        for snapshot in config.pipeline.snapshots:
            path = config.data.raw_directory / snapshot.file
            print(f'Obteniendo movimientos del archivo: {path}')
            insert_movements(con, path)

        print('Procesando movimientos...')
        process(con)
        print('Movimientos procesados exitosamente')


if __name__ == '__main__':
    run()
