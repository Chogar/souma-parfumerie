#!/usr/bin/env bash
# Applique toutes les migrations SQL (002 → 008). 009 = données de test (optionnel).
set -euo pipefail

DB_NAME="${DB_NAME:-souma_parfumerie}"
DB_USER="${DB_USER:-$(whoami)}"
INCLUDE_TEST_SEED="${INCLUDE_TEST_SEED:-0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS=(
  002_cdc_extensions.sql
  003_product_expiry.sql
  004_security_2fa.sql
  005_expenses.sql
  006_store_settings.sql
  007_client_loyalty.sql
  008_sale_returns.sql
  010_sale_return_line_items.sql
  011_client_gifts_received.sql
)

echo "==> Migrations sur $DB_NAME (utilisateur $DB_USER)"
for f in "${MIGRATIONS[@]}"; do
  path="$ROOT/database/migrations/$f"
  if [[ -f "$path" ]]; then
    echo "    → $f"
    psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$path"
  fi
done

if [[ "$INCLUDE_TEST_SEED" == "1" ]]; then
  echo "    → 009_seed_test_products.sql (démo)"
  psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
    -f "$ROOT/database/migrations/009_seed_test_products.sql"
fi

echo "==> Migrations terminées."
