-- Extension CDC : fournisseurs, permissions utilisateur

CREATE TABLE IF NOT EXISTS suppliers (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255) NOT NULL,
    phone       VARCHAR(32),
    email       VARCHAR(128),
    address     TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT FALSE
);

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS permissions JSONB NOT NULL DEFAULT '{}';

ALTER TABLE products
    ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_products_supplier ON products(supplier_id);
