#!/usr/bin/env bash
# Installation base PostgreSQL locale SOUMAPARFUMERIE
set -euo pipefail

DB_NAME="${DB_NAME:-souma_parfumerie}"
DB_USER="${DB_USER:-$(whoami)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Création base $DB_NAME (si absente)"
createdb -U "$DB_USER" "$DB_NAME" 2>/dev/null || true

echo "==> Application schéma"
psql -U "$DB_USER" -d "$DB_NAME" -f "$ROOT/database/schema.sql"

echo "==> Données initiales"
psql -U "$DB_USER" -d "$DB_NAME" -f "$ROOT/database/seeds.sql"

echo "==> Migrations"
DB_NAME="$DB_NAME" DB_USER="$DB_USER" INCLUDE_TEST_SEED="${INCLUDE_TEST_SEED:-0}" \
  "$ROOT/scripts/migrate_db.sh"

echo "==> Terminé. Comptes : admin / caisse — mot de passe : Admin@2026"
echo "    (Manager Chogar : voir database/seeds.sql)"
