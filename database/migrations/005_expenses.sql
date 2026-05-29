-- Dépenses : envois d'argent, achats, sorties diverses

CREATE TABLE IF NOT EXISTS expenses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    expense_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    amount          DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    category        VARCHAR(32) NOT NULL CHECK (category IN (
        'cash_send', 'purchase', 'exit', 'supply', 'other'
    )),
    description     TEXT,
    beneficiary     VARCHAR(128),
    supplier_id     UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    user_id         UUID NOT NULL REFERENCES users(id),
    payment_method  VARCHAR(32) NOT NULL DEFAULT 'cash',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_synced       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
