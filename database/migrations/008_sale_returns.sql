-- Retours vente : demande caissier, validation manager

ALTER TABLE sales DROP CONSTRAINT IF EXISTS sales_status_check;
ALTER TABLE sales ADD CONSTRAINT sales_status_check CHECK (status IN (
    'draft', 'completed', 'cancelled', 'returned'
));

ALTER TABLE sales ADD COLUMN IF NOT EXISTS return_status VARCHAR(32)
    CHECK (return_status IS NULL OR return_status IN ('pending', 'approved', 'rejected'));
ALTER TABLE sales ADD COLUMN IF NOT EXISTS return_reason TEXT;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS return_requested_by UUID REFERENCES users(id);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS return_requested_at TIMESTAMPTZ;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS return_approved_by UUID REFERENCES users(id);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS return_approved_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_sales_return_pending
    ON sales(return_status) WHERE return_status = 'pending';
