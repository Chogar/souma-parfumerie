#!/usr/bin/env bash
# Build release Flutter desktop (windows | macos | linux)
set -euo pipefail

PLATFORM="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/app"

if [[ -z "$PLATFORM" ]]; then
  echo "Usage: $0 <windows|macos|linux> [dart-define args...]"
  echo "Exemple:"
  echo "  $0 windows --dart-define=SOUMA_DB_USER=postgres --dart-define=SOUMA_DB_PASSWORD=secret"
  exit 1
fi

shift || true
EXTRA=("$@")

cd "$APP"
flutter pub get
flutter gen-l10n
flutter analyze
flutter test

case "$PLATFORM" in
  windows)
    flutter build windows --release "${EXTRA[@]}"
    echo "==> Sortie : app/build/windows/x64/runner/Release/"
    ;;
  macos)
    flutter build macos --release "${EXTRA[@]}"
    echo "==> Sortie : app/build/macos/Build/Products/Release/souma_parfumerie.app"
    ;;
  linux)
    flutter build linux --release "${EXTRA[@]}"
    echo "==> Sortie : app/build/linux/x64/release/bundle/"
    ;;
  *)
    echo "Plateforme inconnue : $PLATFORM"
    exit 1
    ;;
esac
