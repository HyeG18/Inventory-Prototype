SELECT 'Product' AS tabla, COUNT(*) AS registros FROM "Product"
UNION ALL SELECT 'Inventory_Movements', COUNT(*) FROM "Inventory_Movements"
UNION ALL SELECT 'Inventory_Balance', COUNT(*) FROM "Inventory_Balance";

SELECT product_id, quantity_on_hand, total_value 
FROM "Inventory_Balance" 
WHERE product_id IN (1, 2);

-- =========================================================================
-- VALIDACION 1: INTEGRIDAD DE TRANSACCIONES Y CONSOLIDACION DE UBICACIONES
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
-- VALIDACION 2: RECALCULO MATEMATICO DE SALDOS FINANCIEROS
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
-- VALIDACION 3: CORRECCION LOGICA DE DIRECCIONALIDAD (ENTRADAS VS SALIDAS)
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
-- VALIDACION 4: PRESERVACION DE ANOMALIAS PARA TESTING
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

Select * from "Product";