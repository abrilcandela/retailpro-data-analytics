-- ============================================================
-- RetailPro - Preentrega 5
-- Consultas SQL con JOIN y UNION
-- Autora: Abril Candela Salinas
-- Base: Ventas_Tech_DB
-- Motor objetivo: PostgreSQL
-- ============================================================

-- Seleccionar la base de datos desde el entorno antes de ejecutar.
-- En PostgreSQL, conectarse previamente a Ventas_Tech_DB.

-- ------------------------------------------------------------
-- CONSULTA 1 - Vista integral de ventas
-- Relaciona ventas con clientes, productos y territorios para
-- obtener una base completa lista para analizar en Power BI.
-- ------------------------------------------------------------
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre AS nombre_cliente,
    c.segmento,
    p.id_producto,
    p.nombre_producto,
    p.categoria,
    p.subcategoria,
    t.id_territorio,
    t.region,
    t.pais,
    t.zona,
    v.cantidad,
    v.precio_unitario,
    v.total_venta,
    v.canal
FROM ventas v
INNER JOIN clientes c
    ON v.id_cliente = c.id_cliente
INNER JOIN productos p
    ON v.id_producto = p.id_producto
INNER JOIN territorios t
    ON v.id_territorio = t.id_territorio
ORDER BY v.fecha_venta, v.id_venta;

-- Hallazgo:
-- Esta consulta integra las cuatro tablas del modelo y mantiene una
-- fila por producto vendido. Permite analizar ventas por cliente,
-- segmento, producto, categoria, territorio, region y canal.


-- ------------------------------------------------------------
-- CONSULTA 2 - Clientes sin ventas
-- Conserva todos los clientes e identifica aquellos que no tienen
-- ninguna operacion asociada en la tabla ventas.
-- ------------------------------------------------------------
SELECT
    c.id_cliente,
    c.nombre,
    c.email,
    c.ciudad,
    c.segmento,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v
    ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.id_cliente;

-- Hallazgo:
-- Los registros obtenidos corresponden a clientes cargados en la
-- base que todavia no realizaron compras. El resultado puede usarse
-- para detectar oportunidades de activacion comercial.


-- ------------------------------------------------------------
-- CONSULTA 3 - Productos sin ventas
-- Conserva todo el catalogo e identifica productos que no aparecen
-- en ninguna operacion de venta.
-- ------------------------------------------------------------
SELECT
    p.id_producto,
    p.nombre_producto,
    p.categoria,
    p.subcategoria,
    p.precio,
    p.costo
FROM productos p
LEFT JOIN ventas v
    ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL
ORDER BY p.id_producto;

-- Hallazgo:
-- Los registros obtenidos corresponden a productos disponibles en el
-- catalogo sin ventas asociadas. Esto permite revisar su demanda,
-- precio, disponibilidad o estrategia comercial.


-- ------------------------------------------------------------
-- CONSULTA 4 - Consolidado de ventas por canal con UNION ALL
-- Combina las operaciones Online y Presencial y calcula, para cada
-- canal, pedidos, unidades, facturacion y ticket promedio.
-- ------------------------------------------------------------
SELECT
    canal,
    COUNT(*) AS cantidad_pedidos,
    SUM(cantidad) AS unidades_vendidas,
    SUM(total_venta) AS total_facturado,
    ROUND(AVG(total_venta), 2) AS ticket_promedio
FROM (
    SELECT
        id_venta,
        cantidad,
        total_venta,
        'Online' AS canal
    FROM ventas
    WHERE canal = 'Online'

    UNION ALL

    SELECT
        id_venta,
        cantidad,
        total_venta,
        'Presencial' AS canal
    FROM ventas
    WHERE canal = 'Presencial'
) ventas_por_canal
GROUP BY canal
ORDER BY total_facturado DESC;

-- Hallazgo:
-- La consulta compara el desempeno de los dos canales sin eliminar
-- operaciones repetidas. UNION ALL es apropiado porque cada fila de
-- ventas debe conservarse para calcular correctamente los totales.


-- ============================================================
-- VALIDACIONES DE CONSISTENCIA
-- ============================================================

-- 1. Comprobar que el JOIN integral no pierda ventas.
SELECT
    (SELECT COUNT(*) FROM ventas) AS ventas_originales,
    COUNT(*) AS ventas_integradas
FROM ventas v
INNER JOIN clientes c
    ON v.id_cliente = c.id_cliente
INNER JOIN productos p
    ON v.id_producto = p.id_producto
INNER JOIN territorios t
    ON v.id_territorio = t.id_territorio;

-- 2. Comprobar que la suma de los canales coincida con el total
-- de operaciones Online y Presencial de la tabla ventas.
SELECT
    COUNT(*) AS cantidad_pedidos,
    SUM(cantidad) AS unidades_vendidas,
    SUM(total_venta) AS total_facturado
FROM ventas
WHERE canal IN ('Online', 'Presencial');
