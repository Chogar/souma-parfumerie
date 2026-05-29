#!/usr/bin/env bash
# Résolution de pg_dump / psql (GUI macOS sans PATH Homebrew).

pg_find_bin() {
  local name="$1"
  local var_name
  var_name="$(echo "$name" | tr '[:lower:]' '[:upper:]')"
  local override="${!var_name:-}"
  if [[ -n "$override" && -x "$override" ]]; then
    echo "$override"
    return 0
  fi
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi
  local candidates=(
    "/opt/homebrew/bin/$name"
    "/usr/local/bin/$name"
    "/Applications/MAMP/Library/bin/$name"
  )
  local v
  for v in /opt/homebrew/opt/postgresql@*/bin/"$name"; do
    [[ -x "$v" ]] && candidates+=("$v")
  done
  for v in /usr/local/opt/postgresql@*/bin/"$name"; do
    [[ -x "$v" ]] && candidates+=("$v")
  done
  for v in /Applications/Postgres.app/Contents/Versions/*/bin/"$name"; do
    [[ -x "$v" ]] && candidates+=("$v")
  done
  local c
  for c in "${candidates[@]}"; do
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

pg_dump_bin() {
  pg_find_bin pg_dump
}

psql_bin() {
  pg_find_bin psql
}
