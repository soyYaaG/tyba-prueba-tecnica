"""Exporta métricas agregadas sin llevar los movimientos completos a Python."""

from duckdb import DuckDBPyConnection

from sql import get_sql

from .core import config, get_connection

REPORTS = {
    'resumen': 'corte',
    'duplicados': 'corte',
    'flujos': 'corte, type',
    'productos_fondos': 'corte, product, fund, type',
    'fechas': 'corte, date, type',
    'acciones': 'accion',
    'validacion': 'filas_t1',
}

TITLES = {
    'resumen': 'Resumen de los cortes',
    'duplicados': 'Llaves repetidas',
    'flujos': 'Montos disponibles por tipo de movimiento',
    'acciones': 'Cambios identificados en la última ejecución',
    'validacion': 'Controles del resultado',
}

LABELS = {
    'corte': 'Corte',
    'movimientos': 'Movimientos',
    'clientes': 'Clientes distintos',
    'entradas': 'Entradas',
    'salidas': 'Salidas',
    'montos_nulos': 'Movimientos sin monto',
    'porcentaje_montos_nulos': 'Movimientos sin monto (%)',
    'montos_negativos': 'Montos negativos',
    'montos_cero': 'Montos iguales a cero',
    'fechas_nulas': 'Fechas sin valor válido',
    'tipos_nulos': 'Tipos sin equivalencia',
    'llaves_nulas': 'Filas sin llave',
    'fecha_minima': 'Primera fecha del movimiento',
    'fecha_maxima': 'Última fecha del movimiento',
    'llaves_repetidas': 'Llaves repetidas',
    'filas_con_llave_repetida': 'Filas con llave repetida',
    'filas_excedentes': 'Filas adicionales por llave',
    'type': 'Tipo',
    'movimientos_con_monto': 'Movimientos con monto',
    'suma_montos_disponibles': 'Suma de montos disponibles',
    'accion': 'Acción',
    'observaciones': 'Observaciones',
    'filas_t': 'Filas de T',
    'filas_t1': 'Filas de T1',
    'filas_finales': 'Filas del resultado',
    'diferencias_contenido': 'Diferencias de contenido con T1',
    'filas_t_clasificadas': 'Filas clasificadas de T',
    'filas_t1_clasificadas': 'Filas clasificadas de T1',
}


def export_analytics(con: DuckDBPyConnection):
    con.execute(get_sql(config.data.sql_directory, 'analytics'))
    output = config.data.output_directory
    output.mkdir(parents=True, exist_ok=True)
    for name, order in REPORTS.items():
        path = str((output / f'analytics_{name}.csv').resolve()).replace("'", "''")
        con.execute(
            f"COPY (SELECT * FROM analytics_{name} ORDER BY {order}) TO '{path}' (HEADER, DELIMITER ',')"
        )

    sections = [
        '# Reporte de movimientos',
        'Este reporte resume el volumen, la calidad de los datos y los cambios '
        'entre los cortes vigentes. El análisis de los archivos de la prueba '
        'y las recomendaciones se encuentran en `INSIGHTS.md`, en la raíz del repositorio.',
        'Las sumas utilizan los montos disponibles y conservan sus signos originales. '
        'Para interpretarlas se debe considerar la información faltante y confirmar '
        'la moneda de los movimientos.',
    ]
    for name in ['resumen', 'duplicados', 'flujos', 'acciones', 'validacion']:
        result = con.execute(f'SELECT * FROM analytics_{name} ORDER BY {REPORTS[name]}')
        columns = [column[0] for column in result.description]
        headers = [LABELS[column] for column in columns]
        rows = result.fetchall()
        if name == 'resumen':
            headers = ['Indicador', *[row[0] for row in rows]]
            rows = [
                (LABELS[column], *[row[index] for row in rows])
                for index, column in enumerate(columns)
                if column != 'corte'
            ]
        sections.append(f'## {TITLES[name]}')
        sections.append(
            '\n'.join(
                [
                    '| ' + ' | '.join(headers) + ' |',
                    '| ' + ' | '.join(['---'] * len(headers)) + ' |',
                    *[
                        '| '
                        + ' | '.join(
                            str(value) if value is not None else 'NULL' for value in row
                        )
                        + ' |'
                        for row in rows
                    ],
                ]
            )
        )
    sections.append(
        'Las acciones corresponden a la última ejecución consolidada. '
        '`AMBIGUO` y `SIN_LLAVE` cuentan las filas de cada corte por separado; '
        'las demás categorías utilizan las correspondencias únicas que permite la llave elegida. '
        'Los archivos CSV complementan este reporte con el detalle por producto, fondo y fecha.'
    )
    (output / 'insights.md').write_text('\n\n'.join(sections) + '\n', encoding='utf-8')
    print(f'Analítica exportada en {output}')


if __name__ == '__main__':
    with get_connection() as connection:
        export_analytics(connection)
