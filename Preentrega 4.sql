-- ============================================================
-- RetailPro - Preentrega 4
-- Extrayendo metricas clave con SQL
-- Autora: Abril Candela Salinas
-- Base: Ventas_Tech_DB
-- Motor objetivo: PostgreSQL
-- ============================================================

-- Seleccionar la base de datos desde el entorno antes de ejecutar.
-- En PostgreSQL, conectarse previamente a Ventas_Tech_DB.

-- ------------------------------------------------------------
-- CONSULTA 1 - Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- ------------------------------------------------------------
SELECT
    EXTRACT(MONTH FROM fecha_venta) AS mes,
    SUM(cantidad * precio_unitario) AS total_facturado,
    COUNT(*) AS cantidad_pedidos,
    ROUND(AVG(cantidad * precio_unitario), 2) AS ticket_promedio
FROM ventas
GROUP BY EXTRACT(MONTH FROM fecha_venta)
ORDER BY mes;


-- ------------------------------------------------------------
-- CONSULTA 2 - Ranking de productos
-- Top 5 de productos por facturacion total.
-- ------------------------------------------------------------
SELECT
    id_producto,
    SUM(cantidad) AS unidades_vendidas,
    SUM(cantidad * precio_unitario) AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC
LIMIT 5;

-- Nota para SQL Server:
-- Reemplazar SELECT por SELECT TOP 5 y eliminar LIMIT 5.


-- ------------------------------------------------------------
-- CONSULTA 3 - Clientes recurrentes
-- Clientes con mas de un pedido, cantidad de pedidos y total gastado.
-- ------------------------------------------------------------
SELECT
    id_cliente,
    COUNT(*) AS cantidad_pedidos,
    SUM(cantidad * precio_unitario) AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;


-- ------------------------------------------------------------
-- CONSULTA 4 - Meses por encima o por debajo del promedio
-- Se calcula primero el total mensual y luego el promedio general
-- de esos totales mensuales.
-- ------------------------------------------------------------
WITH ventas_mensuales AS (
    SELECT
        EXTRACT(MONTH FROM fecha_venta) AS mes,
        SUM(cantidad * precio_unitario) AS total_facturado_mes
    FROM ventas
    GROUP BY EXTRACT(MONTH FROM fecha_venta)
),
promedio_mensual AS (
    SELECT AVG(total_facturado_mes) AS promedio_general
    FROM ventas_mensuales
)
SELECT
    vm.mes,
    vm.total_facturado_mes,
    ROUND(pm.promedio_general, 2) AS promedio_mensual_general,
    CASE
        WHEN vm.total_facturado_mes > pm.promedio_general THEN 'Por encima'
        WHEN vm.total_facturado_mes < pm.promedio_general THEN 'Por debajo'
        ELSE 'Igual al promedio'
    END AS comparacion_promedio
FROM ventas_mensuales vm
CROSS JOIN promedio_mensual pm
ORDER BY vm.mes;


-- ============================================================
-- HALLAZGOS DEL ANALISIS
-- Los siguientes hallazgos corresponden a los 10 registros de
-- ejemplo incluidos en el script Ventas_Tech_DB del modulo 3.
-- ============================================================

-- 1. La facturacion total del conjunto analizado es USD 6.444 y
--    corresponde a 10 pedidos, con un ticket promedio de USD 644,40.
--
-- 2. El producto con id_producto = 1 lidera el ranking: genera
--    USD 3.600 y concentra aproximadamente el 55,87% del total.
--
-- 3. Los clientes con id_cliente 3 y 5 son los recurrentes de mayor
--    valor: cada uno realiza 2 pedidos y acumula USD 1.350.
--
-- Nota de calidad: los datos de ejemplo estan concentrados en un solo
-- mes. Por eso, la comparacion mensual devuelve "Igual al promedio".
-- Para analizar tendencias reales, la base deberia incluir varios meses.
