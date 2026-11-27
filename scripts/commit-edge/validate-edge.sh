#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash validate-edge.sh --p4port protocol:host:port [--expected-server-id id] [--skip-pull-status]

This script performs read-only validation against an already running edge server.
It does not modify P4 Server configuration, service state, trust files, or tickets.
EOF
}

p4port=""
expected_server_id=""
skip_pull_status=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --p4port)
      p4port="${2:-}"
      shift 2
      ;;
    --expected-server-id)
      expected_server_id="${2:-}"
      shift 2
      ;;
    --skip-pull-status)
      skip_pull_status=true
      shift
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

if [[ -z "$p4port" ]]; then
  printf '%s\n' '--p4port is required.' >&2
  exit 2
fi

if ! command -v p4 >/dev/null 2>&1; then
  printf '%s\n' 'p4 command not found.' >&2
  exit 1
fi

info_output="$(p4 -p "$p4port" info)"
printf '%s\n' "$info_output"

if ! grep -Eq 'Server services:.*edge-server' <<<"$info_output"; then
  printf '%s\n' 'Expected an edge-server response, but the server service was not identified as edge-server.' >&2
  exit 1
fi

if [[ -n "$expected_server_id" ]]; then
  server_id="$(p4 -ztag -p "$p4port" info | awk '$2 == "serverID" { print $3; exit }')"
  if [[ -z "$server_id" ]]; then
    printf '%s\n' 'Could not determine the server ID from tagged p4 info output.' >&2
    exit 1
  fi
  printf 'Server ID: %s\n' "$server_id"
  if [[ "$server_id" != "$expected_server_id" ]]; then
    printf 'Expected server ID %s, got %s.\n' "$expected_server_id" "$server_id" >&2
    exit 1
  fi
fi

if [[ "$skip_pull_status" == false ]]; then
  printf '%s\n' 'Replication status:'
  p4 -p "$p4port" pull -lj
fi

printf 'Edge validation completed successfully. Review replication status and P4LOG before declaring the service healthy.\n'