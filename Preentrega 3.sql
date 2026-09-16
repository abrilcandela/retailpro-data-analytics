/* =============================================================
   M3 - PRE-ENTREGA: SCRIPT SQL DE RETAILPRO
   Autora: Abril Candela Salinas
   Motor: SQL Server

   Este script implementa el modelo definido en M1 y M2:
   - Terminologia uniforme: costo / costo_unitario.
   - total_venta es neto del descuento.
   - id_transaccion agrupa productos de una misma compra.
   - nro_linea identifica cada producto dentro de la compra.
   ============================================================= */

/* =============================================================
   SECCION 1 - DEFINICION DEL ESQUEMA (DDL)
   ============================================================= */

IF DB_ID('RetailPro_DB') IS NULL
BEGIN
    CREATE DATABASE RetailPro_DB;
END;
GO

USE RetailPro_DB;
GO

/* Orden inverso de dependencias. */
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS territorios;
GO

CREATE TABLE clientes (
    id_cliente       INT          NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    email            VARCHAR(150) NOT NULL,
    ciudad           VARCHAR(80)  NOT NULL,
    segmento         VARCHAR(30)  NOT NULL,
    fecha_registro   DATE         NOT NULL,

    CONSTRAINT PK_clientes
        PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_clientes_email
        UNIQUE (email),
    CONSTRAINT CK_clientes_segmento
        CHECK (segmento IN ('Particular', 'PyME', 'Corporativo'))
);
GO

CREATE TABLE productos (
    id_producto       INT            NOT NULL,
    nombre_producto   VARCHAR(120)   NOT NULL,
    categoria         VARCHAR(60)    NOT NULL,
    subcategoria      VARCHAR(60)    NOT NULL,
    precio_unitario   DECIMAL(12,2)  NOT NULL,
    costo_unitario    DECIMAL(12,2)  NOT NULL,

    CONSTRAINT PK_productos
        PRIMARY KEY (id_producto),
    CONSTRAINT UQ_productos_nombre
        UNIQUE (nombre_producto),
    CONSTRAINT CK_productos_precio
        CHECK (precio_unitario > 0),
    CONSTRAINT CK_productos_costo
        CHECK (costo_unitario >= 0),
    CONSTRAINT CK_productos_precio_costo
        CHECK (precio_unitario >= costo_unitario)
);
GO

CREATE TABLE territorios (
    id_territorio   INT          NOT NULL,
    region          VARCHAR(50)  NOT NULL,
    pais            VARCHAR(60)  NOT NULL,
    zona            VARCHAR(80)  NOT NULL,

    CONSTRAINT PK_territorios
        PRIMARY KEY (id_territorio),
    CONSTRAINT UQ_territorios_ubicacion
        UNIQUE (region, pais, zona)
);
GO

CREATE TABLE ventas (
    id_venta             INT            NOT NULL,
    id_transaccion       INT            NOT NULL,
    nro_linea            INT            NOT NULL,
    fecha_venta          DATE           NOT NULL,
    id_cliente           INT            NOT NULL,
    id_producto          INT            NOT NULL,
    id_territorio        INT            NOT NULL,
    cantidad             INT            NOT NULL,
    precio_unitario      DECIMAL(12,2)  NOT NULL,
    descuento_importe    DECIMAL(12,2)  NOT NULL
        CONSTRAINT DF_ventas_descuento DEFAULT (0),
    total_venta AS
        CONVERT(DECIMAL(14,2),
            (cantidad * precio_unitario) - descuento_importe
        ) PERSISTED,
    moneda               CHAR(3)        NOT NULL
        CONSTRAINT DF_ventas_moneda DEFAULT ('ARS'),
    canal                VARCHAR(20)    NOT NULL,

    CONSTRAINT PK_ventas
        PRIMARY KEY (id_venta),
    CONSTRAINT UQ_ventas_transaccion_linea
        UNIQUE (id_transaccion, nro_linea),

    CONSTRAINT FK_ventas_clientes
        FOREIGN KEY (id_cliente)
        REFERENCES clientes (id_cliente),
    CONSTRAINT FK_ventas_productos
        FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto),
    CONSTRAINT FK_ventas_territorios
        FOREIGN KEY (id_territorio)
        REFERENCES territorios (id_territorio),

    CONSTRAINT CK_ventas_linea
        CHECK (nro_linea > 0),
    CONSTRAINT CK_ventas_cantidad
        CHECK (cantidad > 0),
    CONSTRAINT CK_ventas_precio
        CHECK (precio_unitario > 0),
    CONSTRAINT CK_ventas_descuento
        CHECK (
            descuento_importe >= 0
            AND descuento_importe <= cantidad * precio_unitario
        ),
    CONSTRAINT CK_ventas_moneda
        CHECK (moneda IN ('ARS', 'USD', 'EUR')),
    CONSTRAINT CK_ventas_canal
        CHECK (canal IN ('Online', 'Presencial'))
);
GO

/* =============================================================
   SECCION 2 - CARGA DE DATOS INICIALES (DML)
   Primero se cargan las tablas maestras y luego ventas.
   ============================================================= */

INSERT INTO clientes
    (id_cliente, nombre, email, ciudad, segmento, fecha_registro)
VALUES
    (1, 'Maria Lopez',  'maria.lopez@mail.com',  'Buenos Aires', 'Particular',  '2024-01-05'),
    (2, 'Carlos Ruiz',  'carlos.ruiz@mail.com',  'Cordoba',      'PyME',        '2024-01-10'),
    (3, 'Ana Gomez',    'ana.gomez@mail.com',    'Rosario',      'Particular',  '2024-02-01'),
    (4, 'Pedro Sanz',   'pedro.sanz@mail.com',   'Mendoza',      'Corporativo', '2024-02-15'),
    (5, 'Laura Torres', 'laura.torres@mail.com', 'Tucuman',      'PyME',        '2024-03-01');
GO

INSERT INTO productos
    (id_producto, nombre_producto, categoria, subcategoria,
     precio_unitario, costo_unitario)
VALUES
    (1, 'Laptop Pro 15',      'Computacion',    'Notebooks',     1200.00, 900.00),
    (2, 'Mouse Inalambrico',  'Accesorios',     'Mouse',           28.00,  14.00),
    (3, 'Monitor 4K 27',      'Computacion',    'Monitores',      450.00, 320.00),
    (4, 'Auriculares BT Pro', 'Audio',          'Auriculares',    120.00,  70.00),
    (5, 'SSD Externo 1TB',    'Almacenamiento', 'Discos externos',130.00,  85.00),
    (6, 'Teclado Mecanico',   'Accesorios',     'Teclados',        95.00,  55.00);
GO

INSERT INTO territorios
    (id_territorio, region, pais, zona)
VALUES
    (1, 'Norte',  'Argentina', 'NOA'),
    (2, 'Norte',  'Argentina', 'NEA'),
    (3, 'Centro', 'Argentina', 'Centro'),
    (4, 'Sur',    'Argentina', 'Patagonia');
GO

/* Diez lineas de venta. Las transacciones 1001, 1003 y 1005
   contienen mas de un producto. total_venta no se inserta porque
   SQL Server lo calcula como importe neto del descuento. */
INSERT INTO ventas
    (id_venta, id_transaccion, nro_linea, fecha_venta,
     id_cliente, id_producto, id_territorio, cantidad,
     precio_unitario, descuento_importe, moneda, canal)
VALUES
    (1,  1001, 1, '2024-03-05', 1, 1, 1, 1, 1200.00, 100.00, 'ARS', 'Online'),
    (2,  1001, 2, '2024-03-05', 1, 2, 1, 2,   28.00,   0.00, 'ARS', 'Online'),
    (3,  1001, 3, '2024-03-05', 1, 6, 1, 1,   95.00,   5.00, 'ARS', 'Online'),
    (4,  1002, 1, '2024-03-06', 2, 3, 2, 2,  450.00,  50.00, 'ARS', 'Presencial'),
    (5,  1003, 1, '2024-03-07', 3, 4, 3, 1,  120.00,   0.00, 'ARS', 'Online'),
    (6,  1003, 2, '2024-03-07', 3, 5, 3, 1,  130.00,  10.00, 'ARS', 'Online'),
    (7,  1004, 1, '2024-03-08', 4, 1, 4, 3, 1200.00, 300.00, 'ARS', 'Presencial'),
    (8,  1005, 1, '2024-03-10', 5, 2, 2, 4,   28.00,  12.00, 'ARS', 'Online'),
    (9,  1005, 2, '2024-03-10', 5, 4, 2, 2,  120.00,  20.00, 'ARS', 'Online'),
    (10, 1006, 1, '2024-03-11', 2, 3, 1, 1,  450.00,   0.00, 'ARS', 'Presencial');
GO

/* =============================================================
   SECCION 3 - CONSULTAS DE VALIDACION
   ============================================================= */

/* 3.1 Verificacion de carga. Resultado esperado: 5, 6, 4 y 10. */
SELECT 'clientes' AS tabla, COUNT(*) AS cantidad_registros FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'territorios', COUNT(*) FROM territorios
UNION ALL
SELECT 'ventas', COUNT(*) FROM ventas;
GO

/* 3.2 Verificacion de integridad y total neto por linea. */
SELECT
    v.id_venta,
    v.id_transaccion,
    v.nro_linea,
    v.fecha_venta,
    c.nombre AS cliente,
    p.nombre_producto,
    t.region,
    t.zona,
    v.cantidad,
    v.precio_unitario,
    v.descuento_importe,
    v.total_venta,
    v.moneda,
    v.canal
FROM ventas AS v
INNER JOIN clientes AS c
    ON v.id_cliente = c.id_cliente
INNER JOIN productos AS p
    ON v.id_producto = p.id_producto
INNER JOIN territorios AS t
    ON v.id_territorio = t.id_territorio
ORDER BY v.id_transaccion, v.nro_linea;
GO

/* 3.3 Verificacion de transacciones con varios productos. */
SELECT
    id_transaccion,
    COUNT(*) AS cantidad_lineas,
    SUM(cantidad) AS unidades,
    SUM(total_venta) AS venta_neta
FROM ventas
GROUP BY id_transaccion
ORDER BY id_transaccion;
GO

/* 3.4 Controles vinculados con los KPIs de M1. */
SELECT
    SUM(total_venta) AS ventas_netas,
    COUNT(DISTINCT id_transaccion) AS cantidad_transacciones,
    CAST(
        SUM(total_venta) / NULLIF(COUNT(DISTINCT id_transaccion), 0)
        AS DECIMAL(14,2)
    ) AS ticket_promedio
FROM ventas;
GO

SELECT
    SUM(v.total_venta - (p.costo_unitario * v.cantidad)) AS margen_bruto
FROM ventas AS v
INNER JOIN productos AS p
    ON v.id_producto = p.id_producto;
GO

/* Fin del script. */
