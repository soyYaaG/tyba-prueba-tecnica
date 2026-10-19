import hashlib
import re
from datetime import UTC, datetime

from .config import config
from .database import get_connection


def run_migrations():
    directory = config.migrations.directory
    con = get_connection()

    try:
        con.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations
            (
                version VARCHAR PRIMARY KEY,
                filename VARCHAR NOT NULL,
                checksum VARCHAR NOT NULL,
                applied_at TIMESTAMP NOT NULL
            )
        """)

        files = sorted(directory.glob('V*.sql'))
        pattern = re.compile(r'^v(\d+)_\w+\.sql$')

        versions = set()

        for file in files:
            match = pattern.fullmatch(file.name)

            if not match:
                raise ValueError(
                    f'El nombre de archivo para la migración no es válido: {file.name}'
                )

            version = int(match.group(1))

            if version in versions:
                raise ValueError(f'La versión de la migración ya existe: {version}')

            versions.add(version)

        for file in files:
            match = pattern.fullmatch(file.name)
            version = int(match.group(1))
            sql_bytes = file.read_bytes()
            sql = sql_bytes.decode('utf-8')
            checksum = hashlib.sha256(sql_bytes).hexdigest()

            existing = con.execute(
                """
                SELECT
                    checksum
                FROM
                    schema_migrations
                WHERE
                    version = ?
                """,
                [str(version)],
            ).fetchone()

            if existing:
                if existing[0] != checksum:
                    raise ValueError(f'La migración ha sido modificada: {file.name}')

                print(f'Omitiendo {file.name}')
                continue

            print(f'Aplicando {file.name}')
            con.execute('BEGIN TRANSACTION')
            try:
                con.execute(sql)
                con.execute(
                    """
                    INSERT INTO schema_migrations
                        (version, filename, checksum, applied_at)
                    VALUES
                        (?, ?, ?, ?)
                    """,
                    [
                        str(version),
                        file.name,
                        checksum,
                        datetime.now(UTC),
                    ],
                )

                con.execute('COMMIT')

            except Exception:
                con.execute('ROLLBACK')
                raise

        print('¡Migraciones completadas exitosamente!')

    finally:
        con.close()


if __name__ == '__main__':
    run_migrations()
