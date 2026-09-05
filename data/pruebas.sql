-- =========================================================================
-- BLOQUE A: PRUEBAS DE INTEGRIDAD ESTRUCTURAL (IE)
-- Objetivo: Identificar anomalias relacionales, nulos criticos y fallos 
-- matematicos en la arquitectura de datos.
-- Criterio de exito general: Todas estas consultas deben devolver 0 filas.
-- =========================================================================

-- =========================================================================
-- VALIDACION IE-01: AUDITORIA DE UNICIDAD DE SKU POR EMPRESA
-- Objetivo: Garantizar que no existan codigos SKU duplicados activos bajo 
-- el mismo grupo empresarial (group_id). Esto previene colisiones durante 
-- la busqueda de productos y asegura la integridad del catalogo.
-- =========================================================================
SELECT 
    group_id, 
    sku, 
    COUNT(*) AS total_duplicados
FROM "Product"
WHERE sku IS NOT NULL
GROUP BY group_id, sku
HAVING COUNT(*) > 1;

-- =========================================================================
-- VALIDACION IE-02: DETECCION DE VALORES NULOS EN CAMPOS CRITICOS
-- Objetivo: Identificar registros incompletos que puedan romper la interfaz 
-- de usuario o los calculos financieros del Asistente IA. Busca productos 
-- sin nombre o SKU, y balances de inventario con cantidades vacias.
-- =========================================================================
SELECT 
    'Producto sin Nombre/SKU' AS anomalia, product_id::text AS id_registro
FROM "Product" 
WHERE name IS NULL OR sku IS NULL
UNION ALL
SELECT 
    'Balance con Cantidad Nula', balance_id::text 
FROM "Inventory_Balance" 
WHERE quantity_on_hand IS NULL OR total_value IS NULL;

-- =========================================================================
-- VALIDACION IE-03: INTEGRIDAD JERARQUICA DE CATEGORIAS (REGISTROS HUERFANOS)
-- Objetivo: Asegurar que todas las subcategorias esten vinculadas a una 
-- categoria padre que realmente exista en la base de datos. Esto previene 
-- errores de visualizacion y filtrado en el arbol de clasificacion.
-- =========================================================================
SELECT 
    hija.category_id AS id_hija, 
    hija.name AS nombre_hija, 
    hija.parent_id AS id_padre_inexistente
FROM "Product_Category" hija
LEFT JOIN "Product_Category" padre ON hija.parent_id = padre.category_id
WHERE hija.parent_id IS NOT NULL 
  AND padre.category_id IS NULL;

-- =========================================================================
-- VALIDACION IE-04: COHERENCIA MATEMATICA ENTRE KARDEX Y SALDOS ACTUALES
-- Objetivo: Cruzar la sumatoria historica de todos los movimientos de 
-- inventario (entradas menos salidas) contra el saldo actual registrado. 
-- Cualquier diferencia detectada indica una falla de integridad transaccional.
-- =========================================================================
WITH MovimientosAgrupados AS (
    SELECT 
        product_id,
        COALESCE(destination_location_id, source_location_id) AS location_id,
        SUM(quantity) AS stock_calculado
    FROM "Inventory_Movements"
    GROUP BY product_id, location_id
)
SELECT 
    b.product_id,
    b.location_id,
    b.quantity_on_hand AS balance_tabla,
    m.stock_calculado AS balance_movimientos,
    (b.quantity_on_hand - m.stock_calculado) AS diferencia
FROM "Inventory_Balance" b
LEFT JOIN MovimientosAgrupados m 
    ON b.product_id = m.product_id 
    AND b.location_id = m.location_id
WHERE b.quantity_on_hand != COALESCE(m.stock_calculado, 0);

-- =========================================================================
-- BLOQUE B: PRUEBAS DE VALIDACION DE ESCENARIO Y SEMILLA
-- Objetivo: Confirmar que la logica de negocio, las direcciones de 
-- inventario y los errores intencionales para testing existan correctamente.
-- =========================================================================

-- =========================================================================
-- VALIDACION B-01: INTEGRIDAD DE TRANSACCIONES Y CONSOLIDACION DE UBICACIONES
-- Objetivo: Confirmar que el historial de 80 movimientos permanece intacto 
-- y auditar que la tabla de saldos (Inventory_Balance) fue purgada de 
-- ubicaciones fantasma (2, 3 y 4). Todo el inventario debe estar 
-- centralizado en la Bodega Principal (Location 1) para asegurar un 
-- punto de verdad unico en el motor analitico.
-- =========================================================================
SELECT 
    'Inventory_Movements' AS tabla, COUNT(*) AS total_registros 
FROM "Inventory_Movements"
UNION ALL 
SELECT 
    'Inventory_Balance (Loc. 1)', COUNT(*) 
FROM "Inventory_Balance" WHERE location_id = 1
UNION ALL 
SELECT 
    'Inventory_Balance (Otras Loc.)', COUNT(*) 
FROM "Inventory_Balance" WHERE location_id != 1;

-- =========================================================================
-- VALIDACION B-02: RECALCULO MATEMATICO DE SALDOS FINANCIEROS
-- Objetivo: Demostrar la correccion de las discrepancias del seed original. 
-- Se cruza la tabla de saldos con el catalogo de productos para validar 
-- que el recuento fisico (ej. 120 y 149 unidades) multiplicado por 
-- su costo promedio refleja el valor total financiero exacto en USD.
-- =========================================================================
SELECT 
    p.name AS "Producto",
    ib.quantity_on_hand AS "Stock Real (Unidades)",
    ib.average_cost AS "Costo Promedio (USD)",
    ib.total_value AS "Valor Total (USD)"
FROM "Inventory_Balance" ib
JOIN "Product" p ON ib.product_id = p.product_id
WHERE p.product_id IN (1, 2)
ORDER BY p.product_id;

-- =========================================================================
-- VALIDACION B-03: CORRECCION LOGICA DE DIRECCIONALIDAD (ENTRADAS VS SALIDAS)
-- Objetivo: Comprobar el comportamiento estructural del inventario. 
-- Las compras (PURCHASE) ahora entran a la Bodega (Destino = 1, Origen = NULL).
-- Las ventas (SALE) ahora salen de la Bodega (Origen = 1, Destino = NULL).
-- Esta integridad referencial previene errores de calculo en futuros KPIs.
-- =========================================================================
SELECT 
    movement_type AS "Tipo de Movimiento",
    quantity AS "Cantidad",
    source_location_id AS "Origen",
    destination_location_id AS "Destino",
    notes AS "Notas"
FROM "Inventory_Movements"
WHERE product_id = 1
ORDER BY movement_date ASC
LIMIT 5;

-- =========================================================================
-- VALIDACION B-04: PRESERVACION DE ANOMALIAS PARA TESTING
-- Objetivo: Confirmar la retencion de los errores tipograficos inyectados 
-- intencionalmente en agosto (simulacion OCR). Mantener este ruido en la 
-- capa de datos es un requisito estrategico para estresar y probar los 
-- filtros de limpieza de texto del futuro dashboard de la Fase 2.
-- =========================================================================
SELECT 
    movement_date AS "Fecha (Agosto)",
    movement_type AS "Tipo",
    notes AS "Notas (Con errores OCR)"
FROM "Inventory_Movements"
WHERE notes ILIKE 'Vnta%' OR notes ILIKE 'Vta%'
ORDER BY movement_date;

-- =========================================================================
-- BLOQUE C: PARCHES DE DATOS Y VERIFICACION FINAL
-- Objetivo: Aplicar correcciones identificadas en pruebas previas.
-- =========================================================================

-- Corregir Kardex y saldo financiero para el Producto 5
UPDATE "Inventory_Balance"
SET 
    quantity_on_hand = 170,
    quantity_available = 170,
    total_value = 425.00
WHERE product_id = 5 AND location_id = 1;

-- Corregir Kardex y saldo financiero para el Producto 10
UPDATE "Inventory_Balance"
SET 
    quantity_on_hand = 200,
    quantity_available = 200,
    total_value = 450.00
WHERE product_id = 10 AND location_id = 1;