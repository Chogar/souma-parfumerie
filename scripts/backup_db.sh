#!/usr/bin/env bash
# Sauvegarde PostgreSQL compressée (CDC §8)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=pg_tools.sh
source "$ROOT/scripts/pg_tools.sh"

DB_NAME="${DB_NAME:-souma_parfumerie}"
DB_USER="${DB_USER:-$(whoami)}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-5432}"
BACKUP_DIR="$ROOT/backups"
mkdir -p "$BACKUP_DIR"

PG_DUMP_BIN="$(pg_dump_bin)" || {
  echo "pg_dump introuvable. Installez PostgreSQL (brew install postgresql@14) ou définissez PG_DUMP=/chemin/vers/pg_dump" >&2
  exit 127
}

STAMP=$(date +%Y%m%d_%H%M%S)
FILE="$BACKUP_DIR/souma_${STAMP}.sql.gz"

"$PG_DUMP_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" | gzip > "$FILE"
echo "Sauvegarde : $FILE"
