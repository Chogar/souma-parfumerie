#!/usr/bin/env bash
# Supprime le démarrage automatique macOS (LaunchAgent)
set -euo pipefail

LABEL="com.experiencetech.souma-manager-api"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || \
  launchctl unload "$PLIST" 2>/dev/null || true

if [[ -f "$PLIST" ]]; then
  rm -f "$PLIST"
fi

"$(cd "$(dirname "$0")/.." && pwd)/scripts/stop_manager_api.sh" 2>/dev/null || true

echo "✅ Démarrage automatique supprimé ($LABEL)"
