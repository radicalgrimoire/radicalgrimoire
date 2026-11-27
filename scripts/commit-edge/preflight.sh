#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  P4ROOT=/path P4PORT=protocol:host:port bash preflight.sh --role commit|edge [--target protocol:host:port]

This script performs read-only checks. It does not modify P4 Server configuration,
service state, trust files, tickets, or data files.
EOF
}

role=""
target=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      role="${2:-}"
      shift 2
      ;;
    --target)
      target="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$role" != "commit" && "$role" != "edge" ]]; then
  printf '%s\n' '--role must be commit or edge.' >&2
  exit 2
fi

if [[ -z "${P4ROOT:-}" || -z "${P4PORT:-}" ]]; then
  printf '%s\n' 'P4ROOT and P4PORT must be set.' >&2
  exit 2
fi

failures=0

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    printf 'OK   command: %s\n' "$1"
  else
    printf 'FAIL command not found: %s\n' "$1" >&2
    failures=$((failures + 1))
  fi
}

run_check() {
  local description="$1"
  shift

  if "$@"; then
    printf 'OK   %s\n' "$description"
  else
    printf 'FAIL %s\n' "$description" >&2
    failures=$((failures + 1))
  fi
}

printf 'Role: %s\nP4ROOT: %s\nP4PORT: %s\n' "$role" "$P4ROOT" "$P4PORT"

check_command p4
check_command p4d

if [[ -d "$P4ROOT" && -r "$P4ROOT" ]]; then
  printf 'OK   readable P4ROOT: %s\n' "$P4ROOT"
else
  printf 'FAIL P4ROOT is not a readable directory: %s\n' "$P4ROOT" >&2
  failures=$((failures + 1))
fi

if [[ -n "${P4SSLDIR:-}" ]]; then
  if [[ -d "$P4SSLDIR" && -r "$P4SSLDIR" ]]; then
    printf 'OK   readable P4SSLDIR: %s\n' "$P4SSLDIR"
  else
    printf 'FAIL P4SSLDIR is not a readable directory: %s\n' "$P4SSLDIR" >&2
    failures=$((failures + 1))
  fi
else
  printf 'WARN P4SSLDIR is not set; confirm this is intentional for non-TLS deployments.\n'
fi

if command -v p4 >/dev/null 2>&1; then
  p4 -V
  run_check "P4 Server response at $P4PORT" p4 -p "$P4PORT" info
fi

if command -v p4d >/dev/null 2>&1; then
  p4d -V
fi

if [[ -n "$target" ]]; then
  if command -v p4 >/dev/null 2>&1; then
    run_check "target P4 Server response at $target" p4 -p "$target" info
  fi
elif [[ "$role" == "edge" ]]; then
  printf '%s\n' 'WARN --target is not set; P4TARGET connectivity was not checked.'
fi

if command -v df >/dev/null 2>&1 && [[ -d "$P4ROOT" ]]; then
  df -h "$P4ROOT"
fi

if (( failures > 0 )); then
  printf 'Preflight failed with %d check(s).\n' "$failures" >&2
  exit 1
fi

printf 'Preflight completed without failed checks. Review warnings before continuing.\n'