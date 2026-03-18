#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${BACKEND_DIR:-"$ROOT_DIR/estate-craft-backend"}"
FRONTEND_DIR="${FRONTEND_DIR:-"$ROOT_DIR/estate-craft-fe"}"

BACKEND_CMD="${BACKEND_CMD:-npm run dev}"
FRONTEND_CMD="${FRONTEND_CMD:-npm run dev}"

backend_pid=""
frontend_pid=""

ensure_deps() {
  local dir="$1"

  if [[ ! -d "$dir" ]]; then
    echo "Missing directory: $dir" >&2
    exit 1
  fi

  if [[ ! -f "$dir/package.json" ]]; then
    echo "Missing package.json in: $dir" >&2
    exit 1
  fi

  if [[ -d "$dir/node_modules" ]]; then
    return 0
  fi

  echo "Installing dependencies in $(basename "$dir")..."
  if [[ -f "$dir/package-lock.json" ]]; then
    (cd "$dir" && npm ci)
  else
    (cd "$dir" && npm install)
  fi
}

cleanup() {
  set +e

  if [[ -n "${frontend_pid:-}" ]] && kill -0 "$frontend_pid" 2>/dev/null; then
    echo "Stopping frontend (pid $frontend_pid)..."
    kill -TERM "$frontend_pid" 2>/dev/null || true
  fi

  if [[ -n "${backend_pid:-}" ]] && kill -0 "$backend_pid" 2>/dev/null; then
    echo "Stopping backend (pid $backend_pid)..."
    kill -TERM "$backend_pid" 2>/dev/null || true
  fi

  [[ -n "${frontend_pid:-}" ]] && wait "$frontend_pid" 2>/dev/null || true
  [[ -n "${backend_pid:-}" ]] && wait "$backend_pid" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

ensure_deps "$BACKEND_DIR"
ensure_deps "$FRONTEND_DIR"

echo "Starting backend: $BACKEND_CMD"
(cd "$BACKEND_DIR" && NODE_ENV="${NODE_ENV:-dev}" $BACKEND_CMD) &
backend_pid="$!"

echo "Starting frontend: $FRONTEND_CMD"
(cd "$FRONTEND_DIR" && $FRONTEND_CMD) &
frontend_pid="$!"

echo "Backend pid: $backend_pid"
echo "Frontend pid: $frontend_pid"
echo "Press Ctrl+C to stop both."

wait
