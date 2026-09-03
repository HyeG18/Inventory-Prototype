-- ============================================================
-- SISTEMA DE INVENTARIO - PROSPERIA v3.1 (post-review + analítica)
-- Fixes aplicados: 1, 2, 3, 4, 5, 6, 7, 8
-- Nuevos: UNIQUE(parent_id,name), has_discount, discount_percentage,
--          índices B-Tree/BRIN, vistas materializadas
-- ============================================================

-- ============================================================
-- SECCIÓN 1: TABLAS EXISTENTES (REFERENCIAS EXTERNAS)
-- ============================================================

CREATE TABLE "Branch" (
  "Id" Serial PRIMARY KEY
);

CREATE TABLE "group" (
  "id" Serial PRIMARY KEY
);

CREATE TABLE "Member" (
  "id" Serial PRIMARY KEY
);

CREATE TABLE "account_tree" (
  "Id" Serial PRIMARY KEY
);

CREATE TABLE "Vendor" (
  "Id" Serial PRIMARY KEY
);

CREATE TABLE "income" (
  "Id" Serial PRIMARY KEY
);

CREATE TABLE "expense" (
  "id" Serial PRIMARY KEY
);

CREATE TABLE "receipt_item" (
  "Id" Serial PRIMARY KEY
);

CREATE TABLE "third_party_integrations" (
  "id" Serial PRIMARY KEY
);

-- ============================================================
-- SECCIÓN 2: CATÁLOGOS MAESTROS
-- ============================================================

-- Unit_Of_Measure: catálogo GLOBAL (sin group_id)
CREATE TABLE "Unit_Of_Measure" (
  "unit_id" Serial PRIMARY KEY,
  "code" Varchar(10) NOT NULL UNIQUE,
  "name" Varchar(50) NOT NULL,
  "abbreviation" Varchar(10),
  "is_base_unit" Boolean NOT NULL DEFAULT false,
  "conversion_factor" Decimal(10,4) NOT NULL DEFAULT 1.0000,
  "created_at" Timestamp NOT NULL DEFAULT NOW()
);

-- Product_Category: jerarquía de categorías
CREATE TABLE "Product_Category" (
  "category_id" Serial PRIMARY KEY,
  "parent_id" Integer,
  "group_id" Integer NOT NULL,
  "account_tree_id" Integer,
  "name" Varchar(100) NOT NULL,
  "description" Text,
  "is_active" Boolean NOT NULL DEFAULT true,
  "created_at" Timestamp NOT NULL DEFAULT NOW(),
  "updated_at" Timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT "FK_Product_Category_parent_id"
    FOREIGN KEY ("parent_id")
      REFERENCES "Product_Category"("category_id"),
  CONSTRAINT "FK_Product_Category_account_tree_id"
    FOREIGN KEY ("account_tree_id")
      REFERENCES "account_tree"("Id"),
  CONSTRAINT "FK_Product_Category_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "UQ_Product_Category_Group_Name"
    UNIQUE ("group_id", "name"),
  CONSTRAINT "UQ_Product_Category_Parent_Name"
    UNIQUE ("parent_id", "name")
);

-- Storage_Location: ubicaciones físicas
CREATE TABLE "Storage_Location" (
  "location_id" Serial PRIMARY KEY,
  "branch_id" Integer NOT NULL,
  "group_id" Integer NOT NULL,
  "name" Varchar(100) NOT NULL,
  "zone" Varchar(50),
  "aisle" Varchar(50),
  "rack" Varchar(50),
  "bin" Varchar(50),
  "is_active" Boolean NOT NULL DEFAULT true,
  "created_at" Timestamp NOT NULL DEFAULT NOW(),
  "updated_at" Timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT "FK_Storage_Location_branch_id"
    FOREIGN KEY ("branch_id")
      REFERENCES "Branch"("Id"),
  CONSTRAINT "FK_Storage_Location_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "UQ_Storage_Location_Branch_Name"
    UNIQUE ("branch_id", "name")
);

-- ============================================================
-- SECCIÓN 3: PRODUCTO
-- ============================================================

CREATE TYPE "product_type_enum" AS ENUM (
  'INVENTORY',
  'NON_INVENTORY',
  'SERVICE'
);

CREATE TABLE "Product" (
  "product_id" Serial PRIMARY KEY,
  "group_id" Integer NOT NULL,
  "category_id" Integer,
  "unit_of_measure_id" Integer NOT NULL,
  "unit_of_purchase_id" Integer,
  "unit_of_sale_id" Integer,
  "created_by" Integer NOT NULL,
  "income_account_id" Integer,
  "expense_account_id" Integer,
  "asset_account_id" Integer,
  "sku" Varchar(100),
  "name" Text NOT NULL,
  "description" Text,
  "is_active" Boolean NOT NULL DEFAULT true,
  "product_type" "product_type_enum" NOT NULL DEFAULT 'INVENTORY',
  "barcode" Varchar(50),
  "brand" Varchar(100),
  "created_at" Timestamp NOT NULL DEFAULT NOW(),
  "updated_at" Timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT "FK_Product_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "FK_Product_category_id"
    FOREIGN KEY ("category_id")
      REFERENCES "Product_Category"("category_id"),
  CONSTRAINT "FK_Product_created_by"
    FOREIGN KEY ("created_by")
      REFERENCES "Member"("id"),
  CONSTRAINT "FK_Product_unit_of_measure_id"
    FOREIGN KEY ("unit_of_measure_id")
      REFERENCES "Unit_Of_Measure"("unit_id"),
  CONSTRAINT "FK_Product_unit_of_purchase_id"
    FOREIGN KEY ("unit_of_purchase_id")
      REFERENCES "Unit_Of_Measure"("unit_id"),
  CONSTRAINT "FK_Product_unit_of_sale_id"
    FOREIGN KEY ("unit_of_sale_id")
      REFERENCES "Unit_Of_Measure"("unit_id"),
  CONSTRAINT "FK_Product_income_account_id"
    FOREIGN KEY ("income_account_id")
      REFERENCES "account_tree"("Id"),
  CONSTRAINT "FK_Product_expense_account_id"
    FOREIGN KEY ("expense_account_id")
      REFERENCES "account_tree"("Id"),
  CONSTRAINT "FK_Product_asset_account_id"
    FOREIGN KEY ("asset_account_id")
      REFERENCES "account_tree"("Id"),
  CONSTRAINT "UQ_Product_Group_SKU"
    UNIQUE ("group_id", "sku"),
  CONSTRAINT "UQ_Product_Group_Barcode"
    UNIQUE ("group_id", "barcode")
);

-- ============================================================
-- SECCIÓN 4: PROVEEDORES Y RELACIONES
-- ============================================================

CREATE TABLE "Product_Supplier" (
  "supplier_id" Serial PRIMARY KEY,
  "product_id" Integer NOT NULL,
  "vendor_id" Integer NOT NULL,
  "group_id" Integer NOT NULL,
  "unit_of_measure_id" Integer,
  "vendor_sku" Text,
  "vendor_price" Numeric,
  "lead_time_days" Integer,
  "is_preferred" Boolean NOT NULL DEFAULT false,
  "currency_code" Varchar(3),
  "created_at" Timestamp NOT NULL DEFAULT NOW(),
  "updated_at" Timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT "FK_Product_Supplier_product_id"
    FOREIGN KEY ("product_id")
      REFERENCES "Product"("product_id"),
  CONSTRAINT "FK_Product_Supplier_vendor_id"
    FOREIGN KEY ("vendor_id")
      REFERENCES "Vendor"("Id"),
  CONSTRAINT "FK_Product_Supplier_unit_of_measure_id"
    FOREIGN KEY ("unit_of_measure_id")
      REFERENCES "Unit_Of_Measure"("unit_id"),
  CONSTRAINT "FK_Product_Supplier_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "UQ_Product_Supplier_Product_Vendor"
    UNIQUE ("product_id", "vendor_id")
);

CREATE UNIQUE INDEX "UQ_Product_Supplier_One_Preferred"
  ON "Product_Supplier" ("product_id")
  WHERE "is_preferred" = true;

CREATE TABLE "Product_Reorder_Policy" (
  "policy_id" Serial PRIMARY KEY,
  "product_id" Integer NOT NULL,
  "location_id" Integer NOT NULL,
  "group_id" Integer NOT NULL,
  "reorder_level" Numeric NOT NULL DEFAULT 0,
  "reorder_quantity" Numeric NOT NULL DEFAULT 0,
  "is_active" Boolean NOT NULL DEFAULT true,
  "created_at" Timestamp NOT NULL DEFAULT NOW(),
  "updated_at" Timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT "FK_Product_Reorder_Policy_product_id"
    FOREIGN KEY ("product_id")
      REFERENCES "Product"("product_id"),
  CONSTRAINT "FK_Product_Reorder_Policy_location_id"
    FOREIGN KEY ("location_id")
      REFERENCES "Storage_Location"("location_id"),
  CONSTRAINT "FK_Product_Reorder_Policy_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "UQ_Product_Reorder_Policy_Product_Location"
    UNIQUE ("product_id", "location_id")
);

-- ============================================================
-- SECCIÓN 5: EXTERNAL MAPPING
-- ============================================================

CREATE TYPE "entity_type_enum" AS ENUM (
  'product',
  'vendor',
  'category',
  'supplier',
  'location',
  'unit_of_measure'
);

CREATE TABLE "External_Mapping" (
  "id" Serial PRIMARY KEY,
  "group_id" Integer NOT NULL,
  "entity_type" "entity_type_enum" NOT NULL,
  "entity_id" Integer NOT NULL,
  "third_party_id" Integer NOT NULL,
  "external_id" Varchar(255) NOT NULL,
  "last_synced_at" Timestamp,
  "metadata" JsonB,

  CONSTRAINT "FK_External_Mapping_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "FK_External_Mapping_third_party_id"
    FOREIGN KEY ("third_party_id")
      REFERENCES "third_party_integrations"("id"),
  CONSTRAINT "UQ_External_Mapping_Entity_System_EntityId"
    UNIQUE ("third_party_id", "entity_type", "entity_id"),
  CONSTRAINT "UQ_External_Mapping_Entity_System_ExternalId_GroupId"
    UNIQUE ("third_party_id", "entity_type", "external_id", "group_id")
);

-- ============================================================
-- SECCIÓN 6: MOVIMIENTOS Y BALANCES
-- ============================================================

CREATE TYPE "movement_type_enum" AS ENUM (
  'PURCHASE',
  'SALE',
  'PURCHASE_RETURN',
  'SALE_RETURN',
  'ADJUSTMENT_IN',
  'ADJUSTMENT_OUT',
  'TRANSFER',
  'PRODUCTION_IN',
  'PRODUCTION_OUT'
);

CREATE TYPE "movement_status_enum" AS ENUM (
  'ACTIVE',
  'REVERSED'
);

CREATE TABLE "Inventory_Movements" (
  "movement_id" Serial PRIMARY KEY,
  "product_id" Integer NOT NULL,
  "expense_id" Integer,
  "income_id" Integer,
  "receipt_item_id" Integer,
  "source_location_id" Integer,
  "destination_location_id" Integer,
  "group_id" Integer NOT NULL,
  "created_by" Integer NOT NULL,
  "reversal_of_movement_id" Integer,
  "status" "movement_status_enum" NOT NULL DEFAULT 'ACTIVE',
  "movement_type" "movement_type_enum" NOT NULL,
  "quantity" Numeric NOT NULL,
  "unit_cost" Numeric NOT NULL,
  "total_cost" Numeric NOT NULL,
  "reference_number" Varchar(100),
  "movement_date" Date NOT NULL,
  "notes" Text,
  "currency_code" Varchar(3),
  "has_discount" Boolean NOT NULL DEFAULT false,
  "discount_percentage" Numeric,
  "created_at" Timestamp NOT NULL DEFAULT NOW(),
  "updated_at" Timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT "FK_Inventory_Movements_product_id"
    FOREIGN KEY ("product_id")
      REFERENCES "Product"("product_id"),
  CONSTRAINT "FK_Inventory_Movements_source_location_id"
    FOREIGN KEY ("source_location_id")
      REFERENCES "Storage_Location"("location_id"),
  CONSTRAINT "FK_Inventory_Movements_destination_location_id"
    FOREIGN KEY ("destination_location_id")
      REFERENCES "Storage_Location"("location_id"),
  CONSTRAINT "FK_Inventory_Movements_created_by"
    FOREIGN KEY ("created_by")
      REFERENCES "Member"("id"),
  CONSTRAINT "FK_Inventory_Movements_income_id"
    FOREIGN KEY ("income_id")
      REFERENCES "income"("Id"),
  CONSTRAINT "FK_Inventory_Movements_expense_id"
    FOREIGN KEY ("expense_id")
      REFERENCES "expense"("id"),
  CONSTRAINT "FK_Inventory_Movements_receipt_item_id"
    FOREIGN KEY ("receipt_item_id")
      REFERENCES "receipt_item"("Id"),
  CONSTRAINT "FK_Inventory_Movements_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "FK_Inventory_Movements_reversal_of_movement_id"
    FOREIGN KEY ("reversal_of_movement_id")
      REFERENCES "Inventory_Movements"("movement_id"),
  CONSTRAINT "CK_Inventory_Movements_Transaction"
    CHECK ("expense_id" IS NULL OR "income_id" IS NULL)
);

-- ============================================================
-- SECCIÓN 7: ÍNDICES
-- ============================================================

-- --- Inventory_Movements ---

-- Reversión única por movimiento
CREATE UNIQUE INDEX "UQ_Inventory_Movements_One_Reversal"
  ON "Inventory_Movements" ("reversal_of_movement_id")
  WHERE "reversal_of_movement_id" IS NOT NULL;

-- B-Tree: filtros transaccionales
CREATE INDEX "IDX_Inventory_Movements_Product_Date"
  ON "Inventory_Movements" ("product_id", "movement_date");
CREATE INDEX "IDX_Inventory_Movements_Movement_Type"
  ON "Inventory_Movements" ("movement_type");
CREATE INDEX "IDX_Inventory_Movements_Movement_Date"
  ON "Inventory_Movements" ("movement_date");
CREATE INDEX "IDX_Inventory_Movements_Group_Id"
  ON "Inventory_Movements" ("group_id");

-- B-Tree analítico (RNF2)
CREATE INDEX "idx_mov_tenant_product"
  ON "Inventory_Movements" ("group_id", "product_id");
CREATE INDEX "idx_mov_type_status"
  ON "Inventory_Movements" ("movement_type", "status");

-- BRIN: series de tiempo e histórico
CREATE INDEX "idx_brin_mov_date"
  ON "Inventory_Movements" USING BRIN ("movement_date");
CREATE INDEX "idx_brin_mov_created"
  ON "Inventory_Movements" USING BRIN ("created_at");
CREATE INDEX "idx_brin_mov_cost"
  ON "Inventory_Movements" USING BRIN ("total_cost");

-- --- Product ---
CREATE INDEX "idx_product_category"
  ON "Product" ("group_id", "category_id");

-- --- Product_Supplier ---
CREATE INDEX "idx_supplier_preferred"
  ON "Product_Supplier" ("product_id")
  WHERE "is_preferred" = true;

-- --- Inventory_Balance ---
CREATE TABLE "Inventory_Balance" (
  "balance_id" Serial PRIMARY KEY,
  "product_id" Integer NOT NULL,
  "location_id" Integer NOT NULL,
  "group_id" Integer NOT NULL,
  "last_movement_id" Integer,
  "quantity_on_hand" Numeric NOT NULL DEFAULT 0,
  "quantity_reserved" Numeric NOT NULL DEFAULT 0,
  "quantity_available" Numeric NOT NULL DEFAULT 0,
  "average_cost" Numeric NOT NULL DEFAULT 0,
  "last_cost" Numeric NOT NULL DEFAULT 0,
  "total_value" Numeric NOT NULL DEFAULT 0,
  "last_movement_date" Date,
  "currency_code" Varchar(3),
  "updated_at" Timestamp NOT NULL DEFAULT NOW(),

  CONSTRAINT "FK_Inventory_Balance_location_id"
    FOREIGN KEY ("location_id")
      REFERENCES "Storage_Location"("location_id"),
  CONSTRAINT "FK_Inventory_Balance_product_id"
    FOREIGN KEY ("product_id")
      REFERENCES "Product"("product_id"),
  CONSTRAINT "FK_Inventory_Balance_last_movement_id"
    FOREIGN KEY ("last_movement_id")
      REFERENCES "Inventory_Movements"("movement_id"),
  CONSTRAINT "FK_Inventory_Balance_group_id"
    FOREIGN KEY ("group_id")
      REFERENCES "group"("id"),
  CONSTRAINT "UQ_Inventory_Balance_Product_Location"
    UNIQUE ("product_id", "location_id")
);

-- B-Tree: stock disponible
CREATE INDEX "IDX_Inventory_Balance_Quantity"
  ON "Inventory_Balance" ("quantity_on_hand")
  WHERE "quantity_on_hand" > 0;

-- B-Tree analítico
CREATE INDEX "idx_balance_currency"
  ON "Inventory_Balance" ("group_id", "currency_code");

-- B-Tree parcial: stockout (alertas inventario agotado)
CREATE INDEX "idx_balance_stockout"
  ON "Inventory_Balance" ("product_id", "location_id")
  WHERE "quantity_on_hand" = 0;

-- BRIN: análisis de inventario lento
CREATE INDEX "idx_brin_balance_aging"
  ON "Inventory_Balance" USING BRIN ("last_movement_date");

-- ============================================================
-- SECCIÓN 8: VISTAS MATERIALIZADAS
-- ============================================================

-- mv_monthly_inventory_snapshot
-- Emula tabla de hechos periódica. Agrupa movimientos por mes.
CREATE MATERIALIZED VIEW "mv_monthly_inventory_snapshot" AS
SELECT
  "group_id",
  "product_id",
  DATE_TRUNC('month', "movement_date") AS "month",
  "movement_type",
  SUM(CASE WHEN "quantity" > 0 THEN "quantity" ELSE 0 END) AS "total_in",
  SUM(CASE WHEN "quantity" < 0 THEN ABS("quantity") ELSE 0 END) AS "total_out",
  SUM("total_cost") AS "total_cost",
  AVG("unit_cost") AS "avg_unit_cost"
FROM "Inventory_Movements"
WHERE "status" = 'ACTIVE'
GROUP BY "group_id", "product_id", DATE_TRUNC('month', "movement_date"), "movement_type"
WITH DATA;

-- mv_reorder_intelligence
-- Cruza stock con políticas de reorden para sugerir órdenes de compra.
CREATE MATERIALIZED VIEW "mv_reorder_intelligence" AS
SELECT
  "p"."group_id",
  "p"."product_id",
  "p"."name" AS "product_name",
  "loc"."location_id",
  "loc"."name" AS "location_name",
  "b"."quantity_available",
  "rp"."reorder_level",
  "rp"."reorder_quantity",
  "rp"."is_active" AS "policy_active",
  CASE WHEN "b"."quantity_available" <= "rp"."reorder_level" THEN true ELSE false END AS "needs_reorder"
FROM "Product" "p"
JOIN "Inventory_Balance" "b" ON "p"."product_id" = "b"."product_id"
JOIN "Storage_Location" "loc" ON "b"."location_id" = "loc"."location_id"
JOIN "Product_Reorder_Policy" "rp"
  ON "p"."product_id" = "rp"."product_id"
 AND "loc"."location_id" = "rp"."location_id"
WHERE "p"."is_active" = true
  AND "rp"."is_active" = true
WITH DATA;

-- ============================================================
-- SECCIÓN 9: TRIGGERS updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION "update_updated_at_column"()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updated_at" = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER "update_Product_updated_at"
  BEFORE UPDATE ON "Product"
  FOR EACH ROW EXECUTE FUNCTION "update_updated_at_column"();

CREATE TRIGGER "update_Product_Category_updated_at"
  BEFORE UPDATE ON "Product_Category"
  FOR EACH ROW EXECUTE FUNCTION "update_updated_at_column"();

CREATE TRIGGER "update_Storage_Location_updated_at"
  BEFORE UPDATE ON "Storage_Location"
  FOR EACH ROW EXECUTE FUNCTION "update_updated_at_column"();

CREATE TRIGGER "update_Product_Supplier_updated_at"
  BEFORE UPDATE ON "Product_Supplier"
  FOR EACH ROW EXECUTE FUNCTION "update_updated_at_column"();

CREATE TRIGGER "update_Product_Reorder_Policy_updated_at"
  BEFORE UPDATE ON "Product_Reorder_Policy"
  FOR EACH ROW EXECUTE FUNCTION "update_updated_at_column"();

CREATE TRIGGER "update_Inventory_Movements_updated_at"
  BEFORE UPDATE ON "Inventory_Movements"
  FOR EACH ROW EXECUTE FUNCTION "update_updated_at_column"();

CREATE TRIGGER "update_Inventory_Balance_updated_at"
  BEFORE UPDATE ON "Inventory_Balance"
  FOR EACH ROW EXECUTE FUNCTION "update_updated_at_column"();
