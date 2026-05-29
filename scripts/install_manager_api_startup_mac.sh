#!/usr/bin/env bash
# Installe le démarrage automatique de l'API Manager au login macOS (LaunchAgent)
# Usage : ./scripts/install_manager_api_startup_mac.sh [port]
set -euo pipefail

PORT="${1:-8080}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DAEMON="$ROOT/scripts/start_manager_api_daemon.sh"
LABEL="com.experiencetech.souma-manager-api"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LOGDIR="$ROOT/logs"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Ce script est réservé à macOS."
  exit 1
fi

chmod +x "$ROOT/scripts/start_manager_api_daemon.sh"
chmod +x "$ROOT/scripts/start_manager_api.sh"
chmod +x "$ROOT/scripts/stop_manager_api.sh" 2>/dev/null || true

mkdir -p "$LOGDIR"
mkdir -p "$HOME/Library/LaunchAgents"

if [[ ! -f "$ROOT/api/.env" ]]; then
  echo "⚠️  api/.env absent — configurez la base avant le premier démarrage."
fi

# Arrêter une instance LaunchAgent existante
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || \
  launchctl unload "$PLIST" 2>/dev/null || true

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${DAEMON}</string>
    <string>${PORT}</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${ROOT}</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>30</integer>
  <key>StandardOutPath</key>
  <string>${LOGDIR}/manager_api_launchd.log</string>
  <key>StandardErrorPath</key>
  <string>${LOGDIR}/manager_api_launchd.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/Applications/MAMP/bin/php/php8.3.1/bin</string>
  </dict>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null || \
  launchctl load "$PLIST"

sleep 3

echo ""
echo "✅ API Manager installée (démarrage auto au login macOS)"
echo "   Label    : $LABEL"
echo "   Portail  : http://127.0.0.1:${PORT}/manager/"
echo "   Santé    : http://127.0.0.1:${PORT}/api/health"
echo "   Logs     : $LOGDIR/manager_api.log"
echo ""
echo "Test : curl http://127.0.0.1:${PORT}/api/health"
echo "Arrêt : ./scripts/stop_manager_api.sh"
echo "Désinstaller : ./scripts/uninstall_manager_api_startup_mac.sh"
echo ""
