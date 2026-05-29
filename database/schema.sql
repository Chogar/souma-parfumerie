-- SOUMAPARFUMERIE — Schéma PostgreSQL (local + cloud)
-- Champs d'audit sync : id (UUID), updated_at, is_synced

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Utilisateurs & sécurité
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code        VARCHAR(32) NOT NULL UNIQUE,
    label_fr    VARCHAR(64) NOT NULL,
    label_ar    VARCHAR(64) NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id         UUID NOT NULL REFERENCES roles(id),
    username        VARCHAR(64) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(128) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at   TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    action      VARCHAR(64) NOT NULL,
    entity      VARCHAR(64),
    entity_id   UUID,
    details     JSONB,
    ip_address  VARCHAR(45),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------------------------------------------------------------------------
-- Catalogue
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_fr     VARCHAR(128) NOT NULL,
    name_ar     VARCHAR(128) NOT NULL,
    parent_id   UUID REFERENCES categories(id) ON DELETE SET NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS products (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id     UUID NOT NULL REFERENCES categories(id),
    barcode         VARCHAR(64) NOT NULL UNIQUE,
    name_fr         VARCHAR(255) NOT NULL,
    name_ar         VARCHAR(255) NOT NULL,
    brand           VARCHAR(128),
    volume_ml       INT,
    purchase_price  DECIMAL(12,2) NOT NULL DEFAULT 0,
    sale_price      DECIMAL(12,2) NOT NULL,
    min_stock_level INT NOT NULL DEFAULT 5,
    expires_at      DATE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced       BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------------------------------------------------------------------------
-- Stock (quantité dérivée des mouvements)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stock_levels (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id  UUID NOT NULL UNIQUE REFERENCES products(id) ON DELETE CASCADE,
    quantity    INT NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID NOT NULL REFERENCES products(id),
    movement_type   VARCHAR(32) NOT NULL CHECK (movement_type IN (
        'sale', 'purchase', 'adjustment', 'return', 'loss', 'sync'
    )),
    quantity_delta  INT NOT NULL,
    reference_type  VARCHAR(32),
    reference_id    UUID,
    note            TEXT,
    user_id         UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced       BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------------------------------------------------------------------------
-- Clients & ventes
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clients (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone       VARCHAR(32) UNIQUE,
    name        VARCHAR(128),
    loyalty_points INT NOT NULL DEFAULT 0,
    gifts_received INT NOT NULL DEFAULT 0,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS sales (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number  VARCHAR(32) NOT NULL UNIQUE,
    user_id         UUID NOT NULL REFERENCES users(id),
    client_id       UUID REFERENCES clients(id),
    subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
    total           DECIMAL(12,2) NOT NULL DEFAULT 0,
    payment_method  VARCHAR(32) NOT NULL CHECK (payment_method IN (
        'cash', 'card', 'mobile', 'mixed'
    )),
    amount_paid     DECIMAL(12,2) NOT NULL DEFAULT 0,
    change_given    DECIMAL(12,2) NOT NULL DEFAULT 0,
    status          VARCHAR(32) NOT NULL DEFAULT 'completed' CHECK (status IN (
        'draft', 'completed', 'cancelled'
    )),
    sold_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS sale_lines (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id         UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      DECIMAL(12,2) NOT NULL,
    line_total      DECIMAL(12,2) NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced       BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------------------------------------------------------------------------
-- Paramètres & sauvegardes
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_settings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key         VARCHAR(64) NOT NULL UNIQUE,
    value       JSONB NOT NULL DEFAULT '{}',
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS backup_logs (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_path   VARCHAR(512) NOT NULL,
    file_size   BIGINT,
    status      VARCHAR(32) NOT NULL DEFAULT 'completed',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced   BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------------------------------------------------------------------------
-- File de synchronisation (métadonnées)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sync_state (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    last_pull_at    TIMESTAMPTZ,
    last_push_at    TIMESTAMPTZ,
    device_id       VARCHAR(128) NOT NULL UNIQUE,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced       BOOLEAN NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------------
-- Index
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_sales_sold_at ON sales(sold_at);
CREATE INDEX IF NOT EXISTS idx_sales_is_synced ON sales(is_synced) WHERE is_synced = FALSE;
CREATE INDEX IF NOT EXISTS idx_products_is_synced ON products(is_synced) WHERE is_synced = FALSE;
CREATE INDEX IF NOT EXISTS idx_stock_movements_is_synced ON stock_movements(is_synced) WHERE is_synced = FALSE;
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at);

-- ---------------------------------------------------------------------------
-- Triggers updated_at
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'roles', 'users', 'categories', 'products', 'stock_levels',
        'stock_movements', 'clients', 'sales', 'sale_lines',
        'app_settings', 'backup_logs', 'sync_state', 'audit_logs'
    ])
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trg_%s_updated_at ON %I;
            CREATE TRIGGER trg_%s_updated_at
            BEFORE UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION set_updated_at();
        ', t, t, t, t);
    END LOOP;
END $$;
