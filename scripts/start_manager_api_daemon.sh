#!/usr/bin/env bash
# Démarre l'API Manager en arrière-plan (LaunchAgent macOS / service)
# Usage : scripts/start_manager_api_daemon.sh [port]
set -euo pipefail

PORT="${1:-8080}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="$ROOT/api"
LOGDIR="$ROOT/logs"
LOG="$LOGDIR/manager_api.log"

mkdir -p "$LOGDIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
}

find_php() {
  if [[ -n "${SOUMA_PHP_BIN:-}" && -x "$SOUMA_PHP_BIN" ]]; then
    echo "$SOUMA_PHP_BIN"
    return 0
  fi
  if command -v php >/dev/null 2>&1; then
    command -v php
    return 0
  fi
  local candidates=(
    /opt/homebrew/bin/php
    /usr/local/bin/php
    /Applications/MAMP/bin/php/php8.3.1/bin/php
    /Applications/MAMP/bin/php/php8.2.26/bin/php
    /Applications/MAMP/bin/php/php8.2.0/bin/php
  )
  local c
  for c in /Applications/MAMP/bin/php/php*/bin/php; do
    [[ -x "$c" ]] && candidates+=("$c")
  done
  for c in "${candidates[@]}"; do
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

export PATH="/opt/homebrew/bin:/usr/local/bin:/Applications/MAMP/bin/php/php8.3.1/bin:${PATH:-}"

PHP_BIN="$(find_php)" || {
  log "ERREUR : PHP introuvable. Installez PHP (Homebrew ou MAMP) ou définissez SOUMA_PHP_BIN."
  exit 1
}

if [[ ! -f "$API/.env" ]]; then
  log "ERREUR : $API/.env manquant"
  exit 1
fi

if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  log "Port $PORT déjà utilisé — API probablement déjà démarrée."
  exit 0
fi

# Attendre PostgreSQL / Tailscale au démarrage Mac
sleep 15

if command -v tailscale >/dev/null 2>&1; then
  if tailscale up >>"$LOG" 2>&1; then
    log "Tailscale actif — IP: $(tailscale ip -4 2>/dev/null || echo '?')"
  else
    log "AVERTISSEMENT : tailscale up a échoué (vérifiez l'app Tailscale)"
  fi
else
  log "Tailscale CLI absent — activez l'app Tailscale manuellement"
fi

if [[ ! -d "$API/vendor" ]]; then
  log "Installation Composer..."
  (cd "$API" && composer install --no-dev --no-interaction >>"$LOG" 2>&1) || {
    log "ERREUR : composer install a échoué"
    exit 1
  }
fi

log "Démarrage API Manager (port $PORT) — PHP: $PHP_BIN"
cd "$API"
exec "$PHP_BIN" -S "0.0.0.0:${PORT}" -t public public/router.php >>"$LOG" 2>&1
