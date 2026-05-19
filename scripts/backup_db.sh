#!/usr/bin/env bash
# Sauvegarde PostgreSQL compressée (CDC §8)
set -euo pipefail

DB_NAME="${DB_NAME:-souma_parfumerie}"
DB_USER="${DB_USER:-postgres}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$ROOT/backups"
mkdir -p "$BACKUP_DIR"

STAMP=$(date +%Y%m%d_%H%M%S)
FILE="$BACKUP_DIR/souma_${STAMP}.sql.gz"

pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$FILE"
echo "Sauvegarde : $FILE"
