# Insights y analítica

## Resumen ejecutivo

El segundo corte contiene **49.000 movimientos, un 2 % menos que el primero**, y mantiene 3.000 clientes distintos. La principal limitación para interpretar los cambios es la ausencia de un identificador único de transacción. Para avanzar con la prueba, utilicé una llave compuesta y separé los casos que no permiten establecer una correspondencia individual.

El procesamiento conserva todos los registros de T1 y permite consultar tanto el resultado como los cambios entre archivos. Antes de utilizar los montos para tomar decisiones, conviene resolver tres aspectos con el origen de los datos: los valores faltantes, el significado de las entradas negativas y la moneda de los movimientos.

| Hallazgo | Implicación | Siguiente paso |
| --- | --- | --- |
| El número de movimientos baja de 50.000 a 49.000. | Hay cambios en el contenido de los cortes que requieren seguimiento. | Revisar incorporaciones, correcciones y retiros por separado. |
| El 2,94 % de los movimientos de T1 no tiene monto. | Los totales monetarios tienen información faltante. | Mostrar la cobertura de datos junto a cada total. |
| T1 contiene 989 entradas con monto negativo. | El signo del monto necesita una definición de negocio. | Confirmar si corresponde a reversos, ajustes o errores. |
| La llave elegida se repite en algunos movimientos. | No todos los cambios pueden atribuirse a una transacción individual. | Obtener un identificador estable y reportar los casos ambiguos. |

Las cifras de este documento corresponden a los archivos entregados con la prueba. El reporte de `data/output/insights.md` se actualiza cada vez que se ejecuta el proyecto.

## 1. Evolución entre cortes

| Indicador | T | T1 |
| --- | ---: | ---: |
| Movimientos | 50.000 | 49.000 |
| Clientes distintos | 3.000 | 3.000 |
| Entradas | 27.606 | 27.100 |
| Salidas | 22.394 | 21.900 |
| Primera fecha del movimiento | 2024-09-15 | 2024-09-15 |
| Última fecha del movimiento | 2024-10-15 | 2024-10-16 |

La reducción de 1.000 movimientos se distribuye entre 506 entradas y 494 salidas. El número de clientes distintos se mantiene, aunque esa cifra por sí sola no indica si son exactamente los mismos clientes.

Los archivos incluyen movimientos de varias fechas. Por eso, la diferencia entre T y T1 debe leerse como una actualización del historial: puede incluir registros nuevos, correcciones y retiros. Para estudiar la actividad de un día específico, el análisis debe agruparse por la fecha del movimiento.

## 2. Calidad de los montos

| Indicador | T | T1 |
| --- | ---: | ---: |
| Movimientos sin monto | 1.543 | 1.440 |
| Porcentaje sin monto | 3,09 % | 2,94 % |
| Montos negativos | 1.034 | 989 |
| Montos iguales a cero | 940 | 903 |

La proporción de montos faltantes baja aproximadamente **0,15 puntos porcentuales**. Es una mejora en la cobertura del segundo corte, aunque no permite afirmar que los registros anteriores hayan sido corregidos, porque el contenido de los archivos también cambia.

Todos los montos negativos observados están clasificados como `ENTRADA`. Podrían corresponder a reversos o ajustes; para darles una interpretación definitiva se necesita confirmar la regla con el negocio. Conservé los valores originales, incluidos los ceros, para evitar introducir una corrección sin sustento.

### Montos disponibles por tipo de movimiento

| Corte | Tipo | Con monto | Sin monto | Suma de montos disponibles |
| --- | --- | ---: | ---: | ---: |
| T | ENTRADA | 26.759 | 847 | 604.445.045.436,15 |
| T | SALIDA | 21.698 | 696 | 528.961.823.360,41 |
| T1 | ENTRADA | 26.328 | 772 | 595.058.249.885,30 |
| T1 | SALIDA | 21.232 | 668 | 518.247.592.097,06 |

Estas sumas conservan los signos originales y excluyen los montos nulos. Su uso es descriptivo: los archivos no informan la moneda y los registros sin monto limitan la cobertura. Para publicar un indicador financiero, primero se deben acordar las reglas de signo y moneda. Reemplazar los nulos por cero ocultaría la información faltante.

## 3. Cambios identificados y casos ambiguos

Para comparar los archivos utilicé la llave `(id_cliente, date, product, type, fund, commercial_name)`, calculada después de normalizar los campos. Cuando la llave permite una correspondencia única, el resultado es el siguiente:

| Resultado | Cantidad |
| --- | ---: |
| Correspondencias sin cambios | 35.142 |
| Correspondencias con cambios | 3.840 |
| Filas presentes solo en T1 | 9.996 |
| Filas presentes solo en T | 10.995 |
| Filas ambiguas de T | 23 |
| Filas ambiguas de T1 | 22 |

Cada corte contiene **10 llaves repetidas, que involucran 20 filas**. Cuando una llave se repite en alguno de los archivos, también se considera ambigua su contraparte. Así se llega a las 23 filas de T y las 22 de T1 que se reportan como `AMBIGUO`.

Conservé estas filas y las separé del conteo de cambios para evitar asignar una correspondencia que los datos no permiten demostrar. Una llave repetida tampoco implica necesariamente que exista una transacción duplicada.

La clasificación cubre todos los registros:

```text
T  = 35.142 + 3.840 + 10.995 + 23 = 50.000
T1 = 35.142 + 3.840 +  9.996 + 22 = 49.000
```

Las inserciones y eliminaciones se interpretan bajo la llave propuesta. Si cambia uno de sus componentes, una misma transacción podría aparecer como una eliminación y una inserción. Los cambios exclusivos de formato de fecha o tipo se reconocen como equivalentes después de normalizar.

## 4. Distribución por producto

En T1, los ocho productos tienen una participación similar por número de movimientos: entre **12,38 % y 12,70 %**.

| Producto | Movimientos en T1 | Participación |
| --- | ---: | ---: |
| Cuenta de Ahorro | 6.221 | 12,70 % |
| CDT | 6.181 | 12,61 % |
| Bonos | 6.169 | 12,59 % |
| Divisas | 6.107 | 12,46 % |
| Fondo de Inversión | 6.095 | 12,44 % |
| Fondo de Pensión | 6.083 | 12,41 % |
| Acciones | 6.079 | 12,41 % |
| ETF | 6.065 | 12,38 % |

La distribución no muestra una concentración marcada en un producto. Para evaluar su importancia económica se necesitarían otras métricas, como montos comparables por moneda o clientes por producto. El número de movimientos por sí solo no mide rentabilidad.

## 5. Prioridades para una operación diaria

1. **Obtener un identificador estable de transacción.** Es el cambio que más ayudaría a distinguir correcciones, incorporaciones y retiros con certeza.
2. **Acordar las reglas de montos y monedas.** Definir el tratamiento de entradas negativas, ceros y valores faltantes antes de publicar indicadores financieros.
3. **Monitorear la calidad de cada corte.** Dar seguimiento a montos faltantes, llaves repetidas y variaciones de volumen, con umbrales acordados con el equipo responsable.

Con los dos cortes disponibles se pueden describir diferencias y problemas de calidad. Para estudiar tendencias o estacionalidad se necesita un historial más amplio.

## 6. Reproducción y validación

Para generar la base de datos y los reportes desde la raíz del repositorio:

```bash
docker compose up --build
```

También se puede ejecutar localmente:

```bash
uv sync --frozen
uv run --frozen python main.py
```

Para actualizar solo la analítica de una base ya procesada:

```bash
uv run --frozen python -m src.analytics
```

Las consultas están en `sql/analytics.sql`. Los resultados se guardan en `data/output/analytics_*.csv` y el reporte automático en `data/output/insights.md`. El detalle de acciones corresponde a la última ejecución consolidada.

Para reproducir la distribución por producto, ejecuta `sql/analytics.sql` y después esta consulta en la misma conexión:

```sql
SELECT product,
       SUM(movimientos) AS movimientos,
       ROUND(100.0 * SUM(movimientos) / SUM(SUM(movimientos)) OVER (), 2) AS porcentaje
FROM analytics_productos_fondos
WHERE corte = 'T1'
GROUP BY product
ORDER BY movimientos DESC, product;
```

La validación de la entrega confirma **49.000 filas finales y cero diferencias de contenido con T1**, incluidas las filas repetidas. La comparación usa `EXCEPT ALL` en ambas direcciones y excluye los identificadores internos. El archivo `analytics_validacion.csv` también confirma que la clasificación cubre las 50.000 filas de T y las 49.000 de T1.
