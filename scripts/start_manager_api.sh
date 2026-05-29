#!/usr/bin/env bash
# Démarre l'API locale + portail Manager (PC boutique)
# Usage : ./scripts/start_manager_api.sh [port]
set -euo pipefail

PORT="${1:-8080}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="$ROOT/api"

if [[ ! -f "$API/.env" ]]; then
  echo "==> Copiez api/.env.example vers api/.env et configurez DB_*"
  exit 1
fi

cd "$API"
if [[ ! -d vendor ]]; then
  composer install --no-dev
fi

echo "==> API Manager : http://0.0.0.0:${PORT}/manager/"
echo "==> Santé API   : http://127.0.0.1:${PORT}/api/health"
echo "    Arrêt : Ctrl+C"
echo ""
echo "    Accès distant : installez Tailscale sur le PC boutique et le téléphone du manager."
echo "    Puis ouvrez http://<IP-TAILSCALE-PC>:${PORT}/manager/ depuis le téléphone."
echo ""

exec php -S "0.0.0.0:${PORT}" -t public
