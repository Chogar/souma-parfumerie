-- Date d'expiration produit (alertes péremption)

ALTER TABLE products
    ADD COLUMN IF NOT EXISTS expires_at DATE;

CREATE INDEX IF NOT EXISTS idx_products_expires_at ON products(expires_at)
    WHERE expires_at IS NOT NULL;
