#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/../frontend"
BACKEND_DIR="$SCRIPT_DIR/../backend"
PID_FILE="$SCRIPT_DIR/.env.pids"
mkdir -p "$SCRIPT_DIR/logs"
BACKEND_LOG="$SCRIPT_DIR/logs/backend.log"
FRONTEND_LOG="$SCRIPT_DIR/logs/frontend.log"

kill_tree() {
  local pid=$1
  local children
  children=$(pgrep -P "$pid" 2>/dev/null) || true
  for child in $children; do
    kill_tree "$child"
  done
  kill "$pid" 2>/dev/null || true
}

teardown() {
  local clear_volumes=${1:-false}
  echo ""
  echo "Tearing down environment..."

  if [[ -f "$PID_FILE" ]]; then
    while IFS= read -r pid; do
      if kill -0 "$pid" 2>/dev/null; then
        kill_tree "$pid"
        echo "  Stopped process tree $pid"
      fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
  fi

  if [[ "$clear_volumes" == "true" ]]; then
    echo "  Removing volumes..."
    (cd "$SCRIPT_DIR" && docker compose down -v)
  else
    (cd "$SCRIPT_DIR" && docker compose down)
  fi
  echo "Done."
}

case "${1:-}" in
  --down|-d)
    teardown false
    exit 0
    ;;
  --down-db)
    teardown true
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Usage: $0 [--down|-d|--down-db]"
    exit 1
    ;;
esac

# ── Docker ────────────────────────────────────────────────────────────────────
echo "Starting Docker environment..."
(cd "$SCRIPT_DIR" && docker compose up -d)

echo "Waiting for PostgreSQL to be ready..."
until docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T postgres \
  pg_isready -U admin -d postgres > /dev/null 2>&1; do
  sleep 1
done

# Ensure the shipping database exists (init.sh only runs on a fresh volume)
docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T postgres \
  psql -U admin -d postgres -tc \
  "SELECT 1 FROM pg_database WHERE datname = 'shipping'" \
  | grep -q 1 || \
  docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T postgres \
  psql -U admin -d postgres -c "CREATE DATABASE shipping;"

echo "PostgreSQL is ready."

# ── Backend ───────────────────────────────────────────────────────────────────
# KAFKA_BOOTSTRAP_SERVERS overrides the local profile default (localhost:9092)
# to use the externally-advertised port exposed by docker-compose (localhost:29092)
echo "Starting backend (Spring Boot - docker profile)..."
(cd "$BACKEND_DIR" && KAFKA_BOOTSTRAP_SERVERS=localhost:29092 mvn spring-boot:run \
  -Dspring-boot.run.profiles=docker \
  -q > "$BACKEND_LOG" 2>&1) &
echo $! >> "$PID_FILE"

# ── Frontend ────────────────────────────────────────────────────────────────────────────
echo "Starting Angular frontend (local config)..."
(cd "$FRONTEND_DIR" && npm run start:local > "$FRONTEND_LOG" 2>&1) &
echo $! >> "$PID_FILE"

echo ""
echo "  Frontend : http://localhost:4200"
echo "  Backend  : http://localhost:8080"
echo "  AKHQ     : http://localhost:9099/ui"
echo ""
echo "  Backend log  : tail -f $BACKEND_LOG"
echo "  Frontend log : tail -f $FRONTEND_LOG"
echo ""
