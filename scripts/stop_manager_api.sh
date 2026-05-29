#!/usr/bin/env bash
# Arrête le serveur API Manager (port 8080 par défaut)
# Usage : ./scripts/stop_manager_api.sh [port]
set -euo pipefail

PORT="${1:-8080}"
LABEL="com.experiencetech.souma-manager-api"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || \
  launchctl unload "$HOME/Library/LaunchAgents/${LABEL}.plist" 2>/dev/null || true

PIDS="$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null || true)"
if [[ -n "$PIDS" ]]; then
  echo "Arrêt du processus sur le port $PORT (PID: $PIDS)"
  kill $PIDS 2>/dev/null || true
  sleep 1
else
  echo "Aucun serveur en écoute sur le port $PORT."
fi

echo "Terminé."
