-- Lignes de retour (quantités par produit) pour retours partiels

CREATE TABLE IF NOT EXISTS sale_return_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    sale_line_id UUID NOT NULL REFERENCES sale_lines(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity_sold INT NOT NULL CHECK (quantity_sold > 0),
    quantity_to_return INT NOT NULL CHECK (quantity_to_return > 0),
    CHECK (quantity_to_return <= quantity_sold),
    UNIQUE (sale_id, sale_line_id)
);

CREATE INDEX IF NOT EXISTS idx_sale_return_line_items_sale
    ON sale_return_line_items(sale_id);
