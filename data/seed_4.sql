-- ============================================================
-- SEED DATA - SISTEMA DE INVENTARIO PROSPERIA v3.1
-- Orden de insercion: FK referential integrity
-- Casing: schema-exact (double-quoted identifiers)
-- Auditoria: Inv Origins Dest, Balances Recalc, Location 2/3/4 eliminados
-- ============================================================

-- ============================================================
-- PASO 1: SECCION 1 - TABLAS BASE (2 registros c/u para FK)
-- ============================================================

INSERT INTO "Branch" ("Id") VALUES (1), (2);
INSERT INTO "group" ("id") VALUES (1), (2);
INSERT INTO "Member" ("id") VALUES (1), (2);
INSERT INTO "account_tree" ("Id") VALUES (1), (2);
INSERT INTO "Vendor" ("Id") VALUES (1), (2);
INSERT INTO "income" ("Id") VALUES (1), (2);
INSERT INTO "expense" ("id") VALUES (1), (2);
INSERT INTO "receipt_item" ("Id") VALUES (1), (2);
INSERT INTO "third_party_integrations" ("id") VALUES (1), (2);

-- ============================================================
-- PASO 2: CATALOGOS - Unit_Of_Measure
-- ============================================================

INSERT INTO "Unit_Of_Measure" ("unit_id", "code", "name", "abbreviation", "is_base_unit", "conversion_factor")
VALUES
  (1, 'UND', 'Unidad', 'UND', true, 1.0000),
  (2, 'KG', 'Kilogramo', 'KG', false, 1.0000),
  (3, 'LT', 'Litro', 'LT', false, 1.0000),
  (4, 'CA', 'Caja', 'CA', false, 1.0000),
  (5, 'GR', 'Gramo', 'GR', false, 0.0010),
  (6, 'MT', 'Metro', 'MT', false, 1.0000);

-- ============================================================
-- PASO 3: Product_Category - Arbol jerarquico (mockData)
-- Estructura:
--   Bebidas (1)
--     Gaseosas (2)
--       Pepsi (3)
--       Jugos (4)
--   Lacteos (5)
--   Snacks (6)
--   Limpieza (7)
--   Abarrotes (8)
--     Granos (9)
--   Sin Categorizar (11)
-- ============================================================

INSERT INTO "Product_Category" ("category_id", "parent_id", "group_id", "name", "description")
VALUES
  (1, NULL, 1, 'Bebidas', 'Bebidas en general'),
  (2, 1, 1, 'Gaseosas', 'Gaseosas y sodas'),
  (3, 2, 1, 'Pepsi', 'Productos Pepsi'),
  (4, 2, 1, 'Jugos', 'Jugos y ne ctares'),
  (5, NULL, 1, 'Lacteos', 'Productos lacteos'),
  (6, NULL, 1, 'Snacks', 'Botanas y snacks'),
  (7, NULL, 1, 'Limpieza', 'Productos de limpieza'),
  (8, NULL, 1, 'Abarrotes', 'Abarrotes generales'),
  (9, 8, 1, 'Granos', 'Granos y cereales'),
  (11, NULL, 1, 'Sin Categorizar', 'Productos sin categoria asignada');

-- ============================================================
-- PASO 4: Storage_Location (2 locations por branch)
-- ============================================================

INSERT INTO "Storage_Location" ("location_id", "branch_id", "group_id", "name", "zone", "aisle", "rack", "bin")
VALUES
  (1, 1, 1, 'Bodega Principal', 'Almacen', 'A', '1', '001'),
  (2, 1, 1, 'Punto de Venta Norte', 'Ventas', 'B', '2', '002'),
  (3, 2, 1, 'Centro Distribucion', 'Almacen', 'C', '3', '003'),
  (4, 2, 1, 'Sucursal Este', 'Ventas', 'D', '4', '004');

-- ============================================================
-- PASO 5: Product (15 registros, 3 con categoria_id = 11)
-- ============================================================

INSERT INTO "Product" ("product_id", "group_id", "category_id", "unit_of_measure_id", "unit_of_purchase_id", "unit_of_sale_id", "created_by", "sku", "name", "description", "is_active", "product_type", "barcode", "brand")
VALUES
  (1, 1, 3, 1, 1, 1, 1, 'PEP-350', 'Pepsi 350ml', 'Bebida Pepsi 350ml', true, 'INVENTORY', '7501234567890', 'PepsiCo'),
  (2, 1, 3, 1, 1, 1, 1, 'PEP-600', 'Pepsi 600ml', 'Bebida Pepsi 600ml', true, 'INVENTORY', '7501234567891', 'PepsiCo'),
  (3, 1, 4, 2, 2, 2, 1, 'JUG-NAR-1L', 'Jugo de Naranja 1L', 'Jugo natural de naranja', true, 'INVENTORY', '7501234567892', 'Citric'),
  (4, 1, 5, 1, 1, 1, 1, 'LEC-DES-1L', 'Leche Deslactosada 1L', 'Leche deslactosada entera', true, 'INVENTORY', '7501234567893', 'Lacteos Valle'),
  (5, 1, 5, 1, 1, 1, 1, 'LEC-ENT-1L', 'Leche Entera 1L', 'Leche entera natural', true, 'INVENTORY', '7501234567894', 'Lacteos Valle'),
  (6, 1, 7, 2, 2, 2, 1, 'DET-1KG', 'Detergente Ropa Blanca 1kg', 'Detergente en polvo para ropa', true, 'INVENTORY', '7501234567895', 'Casa Quimica'),
  (7, 1, 7, 2, 2, 2, 1, 'JAB-LIQ-500', 'Jabon Liquido Manos 500ml', 'Jabon liquido para manos', true, 'INVENTORY', '7501234567896', 'Limpiox'),
  (8, 1, 8, 4, 4, 4, 1, 'ARR-1KG', 'Arroz Superior 1kg', 'Arroz premium importado', true, 'INVENTORY', '7501234567897', 'Molinos Sur'),
  (9, 1, 8, 2, 2, 2, 1, 'FRI-500G', 'Frijoles Rojos 500g', 'Frijoles rojos selectos', true, 'INVENTORY', '7501234567898', 'Granos Andinos'),
  (10, 1, 9, 2, 2, 2, 1, 'LENTE-500G', 'Lentejas 500g', 'Lentejas premium', true, 'INVENTORY', '7501234567899', 'Granos Andinos'),
  (11, 1, 11, 1, 1, 1, 1, 'SERV-INST-01', 'Servicio de Instalacion', 'Servicio instalacion equipos', true, 'SERVICE', NULL, NULL),
  (12, 1, 11, 4, 4, 4, 1, 'CAJA-REGALO', 'Caja de Regalo Varios', 'Caja sorpresa con productos', true, 'NON_INVENTORY', NULL, NULL),
  (13, 1, 11, 2, 2, 2, 1, 'HARINA-1KG', 'Harina de Trigo 1kg', 'Harina multiusos', true, 'INVENTORY', '7501234567900', 'Molinos Central'),
  (14, 1, 6, 1, 1, 1, 1, 'PAPAS-L-150', 'Papas Laythus 150g', 'Papas fritas sabor original', true, 'INVENTORY', '7501234567901', 'SnackCorp'),
  (15, 1, 6, 1, 1, 1, 1, 'CHD-TOR-120', 'Cheetos Torciditos 120g', 'Snack de queso', true, 'INVENTORY', '7501234567902', 'SnackCorp');

-- ============================================================
-- PASO 6: Product_Supplier (relacion products con vendors)
-- ============================================================

INSERT INTO "Product_Supplier" ("product_id", "vendor_id", "group_id", "unit_of_measure_id", "vendor_sku", "vendor_price", "lead_time_days", "is_preferred", "currency_code")
VALUES
  (1, 1, 1, 1, 'PEP-350-DIST', 4.50, 3, true, 'USD'),
  (1, 2, 1, 1, 'PEP-350-ALT', 4.75, 5, false, 'USD'),
  (2, 1, 1, 1, 'PEP-600-DIST', 6.00, 3, true, 'USD'),
  (3, 1, 1, 2, 'JUG-NAR-DIST', 3.20, 4, true, 'USD'),
  (4, 2, 1, 1, 'LEC-DES-DIST', 2.80, 2, true, 'USD'),
  (5, 2, 1, 1, 'LEC-ENT-DIST', 2.50, 2, true, 'USD'),
  (6, 1, 1, 2, 'DET-DIST', 5.40, 5, true, 'USD'),
  (7, 1, 1, 2, 'JAB-LIQ-DIST', 3.90, 4, true, 'USD'),
  (8, 2, 1, 2, 'ARR-DIST', 2.10, 7, true, 'USD'),
  (9, 2, 1, 2, 'FRIJ-DIST', 1.80, 6, true, 'USD'),
  (10, 2, 1, 2, 'LENT-DIST', 2.25, 6, true, 'USD'),
  (13, 2, 1, 2, 'HAR-DIST', 1.50, 5, true, 'USD'),
  (14, 1, 1, 1, 'PAPAS-DIST', 2.20, 3, true, 'USD'),
  (15, 1, 1, 1, 'CHD-DIST', 1.90, 3, true, 'USD');

-- ============================================================
-- PASO 6.5: Product_Reorder_Policy (Bodega Principal, location_id=1)
-- ============================================================

INSERT INTO "Product_Reorder_Policy" ("product_id", "location_id", "group_id", "reorder_level", "reorder_quantity", "is_active")
VALUES
  (1, 1, 1, 20, 50, true),
  (4, 1, 1, 25, 60, true),
  (6, 1, 1, 15, 40, false),
  (8, 1, 1, 40, 100, true),
  (9, 1, 1, 30, 80, true);

-- ============================================================
-- PASO 7: Inventory_Movements (80 transacciones)
-- Fechas: Mar-Ago 2026. Origen/Destino CORREGIDO:
--   PURCHASE: source_location_id=NULL, destination_location_id=1
--   SALE:     source_location_id=1, destination_location_id=NULL
-- OCR errors en 3 notas Agosto (intencionados)
-- ============================================================

INSERT INTO "Inventory_Movements" ("product_id", "group_id", "created_by", "source_location_id", "destination_location_id", "movement_type", "quantity", "unit_cost", "total_cost", "reference_number", "movement_date", "notes", "currency_code")
VALUES
-- MARZO 2026 (10 movimientos)
  (1, 1, 1, NULL, 1, 'PURCHASE', 50, 4.50, 225.00, 'PO-2026-001', '2026-03-01', 'Compra inicial', 'USD'),
  (1, 1, 1, 1, NULL, 'SALE', -5, 6.00, 30.00, 'INV-2026-001', '2026-03-03', 'Venta mostrador', 'USD'),
  (2, 1, 1, NULL, 1, 'PURCHASE', 30, 6.00, 180.00, 'PO-2026-002', '2026-03-05', 'Compra reposicion', 'USD'),
  (2, 1, 1, 1, NULL, 'SALE', -3, 7.50, 22.50, 'INV-2026-002', '2026-03-07', 'Venta mostrador', 'USD'),
  (4, 1, 1, NULL, 1, 'PURCHASE', 100, 2.80, 280.00, 'PO-2026-003', '2026-03-10', 'Compra lacteos', 'USD'),
  (4, 1, 1, 1, NULL, 'SALE', -15, 4.20, 63.00, 'INV-2026-003', '2026-03-12', 'Venta lacteos', 'USD'),
  (6, 1, 1, NULL, 1, 'PURCHASE', 40, 5.40, 216.00, 'PO-2026-004', '2026-03-15', 'Compra limpieza', 'USD'),
  (6, 1, 1, 1, NULL, 'SALE', -8, 7.50, 60.00, 'INV-2026-004', '2026-03-18', 'Venta limpieza', 'USD'),
  (8, 1, 1, NULL, 1, 'PURCHASE', 200, 2.10, 420.00, 'PO-2026-005', '2026-03-20', 'Compra abarrotes', 'USD'),
  (8, 1, 1, 1, NULL, 'SALE', -25, 3.50, 87.50, 'INV-2026-005', '2026-03-25', 'Venta abarrotes', 'USD'),

-- ABRIL 2026 (14 movimientos)
  (3, 1, 1, NULL, 1, 'PURCHASE', 60, 3.20, 192.00, 'PO-2026-006', '2026-04-02', 'Compra jugos', 'USD'),
  (3, 1, 1, 1, NULL, 'SALE', -10, 4.80, 48.00, 'INV-2026-006', '2026-04-04', 'Venta jugos', 'USD'),
  (5, 1, 1, NULL, 1, 'PURCHASE', 80, 2.50, 200.00, 'PO-2026-007', '2026-04-06', 'Compra leche entera', 'USD'),
  (5, 1, 1, 1, NULL, 'SALE', -20, 3.80, 76.00, 'INV-2026-007', '2026-04-08', 'Venta leche entera', 'USD'),
  (7, 1, 1, NULL, 1, 'PURCHASE', 45, 3.90, 175.50, 'PO-2026-008', '2026-04-10', 'Compra jabon', 'USD'),
  (7, 1, 1, 1, NULL, 'SALE', -12, 5.50, 66.00, 'INV-2026-008', '2026-04-12', 'Venta jabon', 'USD'),
  (9, 1, 1, NULL, 1, 'PURCHASE', 150, 1.80, 270.00, 'PO-2026-009', '2026-04-14', 'Compra frijoles', 'USD'),
  (9, 1, 1, 1, NULL, 'SALE', -30, 2.80, 84.00, 'INV-2026-009', '2026-04-16', 'Venta frijoles', 'USD'),
  (10, 1, 1, NULL, 1, 'PURCHASE', 100, 2.25, 225.00, 'PO-2026-010', '2026-04-18', 'Compra lentejas', 'USD'),
  (10, 1, 1, 1, NULL, 'SALE', -20, 3.50, 70.00, 'INV-2026-010', '2026-04-20', 'Venta lentejas', 'USD'),
  (13, 1, 1, NULL, 1, 'PURCHASE', 120, 1.50, 180.00, 'PO-2026-011', '2026-04-22', 'Compra harina', 'USD'),
  (13, 1, 1, 1, NULL, 'SALE', -35, 2.50, 87.50, 'INV-2026-011', '2026-04-24', 'Venta harina', 'USD'),
  (14, 1, 1, NULL, 1, 'PURCHASE', 80, 2.20, 176.00, 'PO-2026-012', '2026-04-26', 'Compra papas', 'USD'),
  (14, 1, 1, 1, NULL, 'SALE', -25, 3.20, 80.00, 'INV-2026-012', '2026-04-28', 'Venta papas', 'USD'),

-- MAYO 2026 (14 movimientos)
  (1, 1, 1, NULL, 1, 'PURCHASE', 100, 4.50, 450.00, 'PO-2026-013', '2026-05-03', 'Compra gran escala', 'USD'),
  (1, 1, 1, 1, NULL, 'SALE', -30, 6.00, 180.00, 'INV-2026-013', '2026-05-05', 'Venta mayoreo', 'USD'),
  (2, 1, 1, NULL, 1, 'PURCHASE', 60, 6.00, 360.00, 'PO-2026-014', '2026-05-07', 'Reposicion pepsi', 'USD'),
  (2, 1, 1, 1, NULL, 'SALE', -18, 7.50, 135.00, 'INV-2026-014', '2026-05-09', 'Venta pepsi', 'USD'),
  (3, 1, 1, NULL, 1, 'PURCHASE', 40, 3.20, 128.00, 'PO-2026-015', '2026-05-11', 'Reposicion jugos', 'USD'),
  (4, 1, 1, NULL, 1, 'PURCHASE', 150, 2.80, 420.00, 'PO-2026-016', '2026-05-13', 'Compra lacteos mayo', 'USD'),
  (4, 1, 1, 1, NULL, 'SALE', -40, 4.20, 168.00, 'INV-2026-015', '2026-05-15', 'Venta lacteos mayo', 'USD'),
  (5, 1, 1, NULL, 1, 'PURCHASE', 90, 2.50, 225.00, 'PO-2026-017', '2026-05-17', 'Reposicion leche', 'USD'),
  (6, 1, 1, NULL, 1, 'PURCHASE', 50, 5.40, 270.00, 'PO-2026-018', '2026-05-19', 'Compra limpieza mayo', 'USD'),
  (6, 1, 1, 1, NULL, 'SALE', -15, 7.50, 112.50, 'INV-2026-016', '2026-05-21', 'Venta limpieza mayo', 'USD'),
  (7, 1, 1, NULL, 1, 'PURCHASE', 35, 3.90, 136.50, 'PO-2026-019', '2026-05-23', 'Reposicion jabon', 'USD'),
  (8, 1, 1, NULL, 1, 'PURCHASE', 180, 2.10, 378.00, 'PO-2026-020', '2026-05-25', 'Compra arroz mayo', 'USD'),
  (8, 1, 1, 1, NULL, 'SALE', -45, 3.50, 157.50, 'INV-2026-017', '2026-05-27', 'Venta arroz mayo', 'USD'),
  (15, 1, 1, NULL, 1, 'PURCHASE', 70, 1.90, 133.00, 'PO-2026-021', '2026-05-29', 'Compra cheetos', 'USD'),

-- JUNIO 2026 (14 movimientos)
  (9, 1, 1, NULL, 1, 'PURCHASE', 120, 1.80, 216.00, 'PO-2026-022', '2026-06-02', 'Reposicion frijoles', 'USD'),
  (9, 1, 1, 1, NULL, 'SALE', -25, 2.80, 70.00, 'INV-2026-018', '2026-06-04', 'Venta frijoles jun', 'USD'),
  (10, 1, 1, NULL, 1, 'PURCHASE', 80, 2.25, 180.00, 'PO-2026-023', '2026-06-06', 'Reposicion lentejas', 'USD'),
  (10, 1, 1, 1, NULL, 'SALE', -22, 3.50, 77.00, 'INV-2026-019', '2026-06-08', 'Venta lentejas jun', 'USD'),
  (13, 1, 1, NULL, 1, 'PURCHASE', 100, 1.50, 150.00, 'PO-2026-024', '2026-06-10', 'Reposicion harina', 'USD'),
  (14, 1, 1, NULL, 1, 'PURCHASE', 90, 2.20, 198.00, 'PO-2026-025', '2026-06-12', 'Reposicion papas', 'USD'),
  (14, 1, 1, 1, NULL, 'SALE', -30, 3.20, 96.00, 'INV-2026-020', '2026-06-14', 'Venta papas jun', 'USD'),
  (15, 1, 1, 1, NULL, 'SALE', -20, 2.80, 56.00, 'INV-2026-021', '2026-06-16', 'Venta cheetos jun', 'USD'),
  (1, 1, 1, 1, NULL, 'SALE', -40, 6.00, 240.00, 'INV-2026-022', '2026-06-18', 'Venta pepsi jun', 'USD'),
  (2, 1, 1, NULL, 1, 'PURCHASE', 50, 6.00, 300.00, 'PO-2026-026', '2026-06-20', 'Compra pepsi jun', 'USD'),
  (3, 1, 1, NULL, 1, 'PURCHASE', 55, 3.20, 176.00, 'PO-2026-027', '2026-06-22', 'Compra jugos jun', 'USD'),
  (4, 1, 1, NULL, 1, 'PURCHASE', 120, 2.80, 336.00, 'PO-2026-028', '2026-06-24', 'Compra lacteos jun', 'USD'),
  (4, 1, 1, 1, NULL, 'SALE', -50, 4.20, 210.00, 'INV-2026-023', '2026-06-26', 'Venta lacteos jun', 'USD'),
  (5, 1, 1, 1, NULL, 'SALE', -35, 3.80, 133.00, 'INV-2026-024', '2026-06-28', 'Venta leche jun', 'USD'),

-- JULIO 2026 (14 movimientos)
  (6, 1, 1, NULL, 1, 'PURCHASE', 60, 5.40, 324.00, 'PO-2026-029', '2026-07-02', 'Compra limpieza jul', 'USD'),
  (6, 1, 1, 1, NULL, 'SALE', -20, 7.50, 150.00, 'INV-2026-025', '2026-07-04', 'Venta limpieza jul', 'USD'),
  (7, 1, 1, NULL, 1, 'PURCHASE', 40, 3.90, 156.00, 'PO-2026-030', '2026-07-06', 'Compra jabon jul', 'USD'),
  (7, 1, 1, 1, NULL, 'SALE', -14, 5.50, 77.00, 'INV-2026-026', '2026-07-08', 'Venta jabon jul', 'USD'),
  (8, 1, 1, NULL, 1, 'PURCHASE', 200, 2.10, 420.00, 'PO-2026-031', '2026-07-10', 'Compra arroz jul', 'USD'),
  (8, 1, 1, 1, NULL, 'SALE', -55, 3.50, 192.50, 'INV-2026-027', '2026-07-12', 'Venta arroz jul', 'USD'),
  (9, 1, 1, NULL, 1, 'PURCHASE', 100, 1.80, 180.00, 'PO-2026-032', '2026-07-14', 'Reposicion frijoles jul', 'USD'),
  (10, 1, 1, NULL, 1, 'PURCHASE', 90, 2.25, 202.50, 'PO-2026-033', '2026-07-16', 'Reposicion lentejas jul', 'USD'),
  (10, 1, 1, 1, NULL, 'SALE', -28, 3.50, 98.00, 'INV-2026-028', '2026-07-18', 'Venta lentejas jul', 'USD'),
  (13, 1, 1, NULL, 1, 'PURCHASE', 110, 1.50, 165.00, 'PO-2026-034', '2026-07-20', 'Reposicion harina jul', 'USD'),
  (14, 1, 1, NULL, 1, 'PURCHASE', 75, 2.20, 165.00, 'PO-2026-035', '2026-07-22', 'Reposicion papas jul', 'USD'),
  (14, 1, 1, 1, NULL, 'SALE', -28, 3.20, 89.60, 'INV-2026-029', '2026-07-24', 'Venta papas jul', 'USD'),
  (15, 1, 1, NULL, 1, 'PURCHASE', 60, 1.90, 114.00, 'PO-2026-036', '2026-07-26', 'Compra cheetos jul', 'USD'),
  (15, 1, 1, 1, NULL, 'SALE', -22, 2.80, 61.60, 'INV-2026-030', '2026-07-28', 'Venta cheetos jul', 'USD'),

-- AGOSTO 2026 (14 movimientos - hasta hoy 27)
-- OCR: 3 errores intencionales en notas (simulan fallos OCR)
  (1, 1, 1, NULL, 1, 'PURCHASE', 80, 4.50, 360.00, 'PO-2026-037', '2026-08-03', 'Compra pepsi ago', 'USD'),
  (1, 1, 1, 1, NULL, 'SALE', -35, 6.00, 210.00, 'INV-2026-031', '2026-08-05', 'Vnta peps cola mostrador', 'USD'),
  (2, 1, 1, NULL, 1, 'PURCHASE', 45, 6.00, 270.00, 'PO-2026-038', '2026-08-07', 'Compra pepsi 600ml ago', 'USD'),
  (2, 1, 1, 1, NULL, 'SALE', -15, 7.50, 112.50, 'INV-2026-032', '2026-08-09', 'Venta pepsi 600ml ago', 'USD'),
  (3, 1, 1, NULL, 1, 'PURCHASE', 50, 3.20, 160.00, 'PO-2026-039', '2026-08-11', 'Compra jugos ago', 'USD'),
  (3, 1, 1, 1, NULL, 'SALE', -18, 4.80, 86.40, 'INV-2026-033', '2026-08-13', 'Venta jugos ago', 'USD'),
  (4, 1, 1, NULL, 1, 'PURCHASE', 100, 2.80, 280.00, 'PO-2026-040', '2026-08-15', 'Compra lacteos', 'USD'),
  (5, 1, 1, NULL, 1, 'PURCHASE', 85, 2.50, 212.50, 'PO-2026-041', '2026-08-17', 'Compra leche entera ago', 'USD'),
  (5, 1, 1, 1, NULL, 'SALE', -30, 3.80, 114.00, 'INV-2026-034', '2026-08-19', 'Venta leche ago', 'USD'),
  (6, 1, 1, NULL, 1, 'PURCHASE', 55, 5.40, 297.00, 'PO-2026-042', '2026-08-21', 'Compra limpieza ago', 'USD'),
  (6, 1, 1, 1, NULL, 'SALE', -16, 7.50, 120.00, 'INV-2026-035', '2026-08-23', 'Venta limpieza ago', 'USD'),
  (8, 1, 1, NULL, 1, 'PURCHASE', 160, 2.10, 336.00, 'PO-2026-043', '2026-08-25', 'Compra arroz ago', 'USD'),
  (8, 1, 1, 1, NULL, 'SALE', -40, 3.50, 140.00, 'INV-2026-036', '2026-08-26', 'Vta arroz preferncial', 'USD'),
  (15, 1, 1, NULL, 1, 'PURCHASE', 50, 1.90, 95.00, 'PO-2026-044', '2026-08-27', 'Compra cheetos ago', 'USD');

-- ============================================================
-- PASO 8: Inventory_Balance (solo location_id=1, recalculado)
-- Recalculo completo desde movimientos (option A: sin loc 2/3/4)
-- ============================================================

INSERT INTO "Inventory_Balance" ("product_id", "location_id", "group_id", "quantity_on_hand", "quantity_reserved", "quantity_available", "average_cost", "last_cost", "total_value", "last_movement_date", "currency_code")
VALUES
-- Todos los productos con saldo en Bodega Principal (location_id=1)
-- Recalculado: SUM(movements) para cada product_id
  (1, 1, 1, 120, 0, 120, 4.50, 4.50, 540.00, '2026-08-05', 'USD'),
  (2, 1, 1, 149, 0, 149, 6.00, 6.00, 894.00, '2026-08-09', 'USD'),
  (3, 1, 1, 177, 0, 177, 3.20, 3.20, 566.40, '2026-08-13', 'USD'),
  (4, 1, 1, 365, 0, 365, 2.80, 2.80, 1022.00, '2026-08-15', 'USD'),
  (5, 1, 1, 170, 0, 170, 2.50, 2.50, 425.00, '2026-08-19', 'USD'),
  (6, 1, 1, 146, 0, 146, 5.40, 5.40, 788.40, '2026-08-21', 'USD'),
  (7, 1, 1, 94, 0, 94, 3.90, 3.90, 366.60, '2026-07-08', 'USD'),
  (8, 1, 1, 575, 0, 575, 2.10, 2.10, 1207.50, '2026-08-26', 'USD'),
  (9, 1, 1, 315, 0, 315, 1.80, 1.80, 567.00, '2026-07-14', 'USD'),
  (10, 1, 1, 200, 0, 200, 2.25, 2.25, 450.00, '2026-07-18', 'USD'),
  (13, 1, 1, 295, 0, 295, 1.50, 1.50, 442.50, '2026-07-20', 'USD'),
  (14, 1, 1, 162, 0, 162, 2.20, 2.20, 356.40, '2026-07-24', 'USD'),
  (15, 1, 1, 138, 0, 138, 1.90, 1.90, 262.20, '2026-08-27', 'USD');

-- ============================================================
-- VERIFICACIONES POST-INSERCION
-- ============================================================

SELECT 'Branch' AS tabla, COUNT(*) AS registros FROM "Branch"
UNION ALL SELECT 'group', COUNT(*) FROM "group"
UNION ALL SELECT 'Member', COUNT(*) FROM "Member"
UNION ALL SELECT 'Vendor', COUNT(*) FROM "Vendor"
UNION ALL SELECT 'Unit_Of_Measure', COUNT(*) FROM "Unit_Of_Measure"
UNION ALL SELECT 'Product_Category', COUNT(*) FROM "Product_Category"
UNION ALL SELECT 'Storage_Location', COUNT(*) FROM "Storage_Location"
UNION ALL SELECT 'Product', COUNT(*) FROM "Product"
UNION ALL SELECT 'Product_Supplier', COUNT(*) FROM "Product_Supplier"
UNION ALL SELECT 'Product_Reorder_Policy', COUNT(*) FROM "Product_Reorder_Policy"
UNION ALL SELECT 'Inventory_Movements', COUNT(*) FROM "Inventory_Movements"
UNION ALL SELECT 'Inventory_Balance', COUNT(*) FROM "Inventory_Balance";

-- ============================================================
-- COMPILACION ANALITICA - Vistas materializadas
-- ============================================================

REFRESH MATERIALIZED VIEW "mv_monthly_inventory_snapshot";
REFRESH MATERIALIZED VIEW "mv_reorder_intelligence";
