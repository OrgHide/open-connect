#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Container entry point for Open Connect (Production).
# Handles secret key generation, optional Ollama/CUDA/Playwright setup,
# HuggingFace Space deployment, and launches the uvicorn server.
# Includes health monitoring and self-healing capabilities.
# ---------------------------------------------------------------------------

# Default optional env vars that we test below with bash's `,,` lowercase
# expansion. The two can't be combined inline (`${VAR:-default,,}` makes
# the default literal `,,`), so we normalise once up front and the simple
# `${VAR,,}` form stays safe under `set -u` everywhere else.
: "${WEB_LOADER_ENGINE:=}" "${USE_OLLAMA_DOCKER:=}" "${USE_CUDA_DOCKER:=}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR" || exit 1

# ── Logging Setup ───────────────────────────────────────────────────────────
LOG_FILE="${LOG_FILE:-/app/backend/startup.log}"
exec > >(tee -a "$LOG_FILE") 2>&1

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

log_warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $1"
}

# ── Startup Banner ───────────────────────────────────────────────────────────
log_info "=============================================="
log_info "Open Connect - Production Startup"
log_info "=============================================="
log_info "Environment: ${ENV:-development}"
log_info "Docker Mode: ${DOCKER:-false}"
log_info "Hostname: ${HOSTNAME:-unknown}"
log_info "=============================================="

# ── Playwright browser installation (if configured) ──────────────────────────

if [[ "${WEB_LOADER_ENGINE,,}" == "playwright" ]]; then
  if [[ -z "${PLAYWRIGHT_WS_URL:-}" ]]; then
    log_info "Installing Playwright Chromium browser..."
    playwright install chromium
    playwright install-deps chromium
  fi
  python -c "import nltk; nltk.download('punkt_tab')"
fi

# ── Secret key setup ─────────────────────────────────────────────────────────

KEY_FILE="${WEBUI_SECRET_KEY_FILE:-.webui_secret_key}"
WEBUI_SECRET_KEY_LENGTH="${WEBUI_SECRET_KEY_LENGTH:-24}"
PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"

if [[ -z "${WEBUI_SECRET_KEY:-}" && -z "${WEBUI_JWT_SECRET_KEY:-}" ]]; then
  log_info "No WEBUI_SECRET_KEY environment variable set, loading from file."

  if [[ ! -f "$KEY_FILE" ]]; then
    log_info "Generating new WEBUI_SECRET_KEY..."
    if ! [[ "$WEBUI_SECRET_KEY_LENGTH" =~ ^[1-9][0-9]*$ ]]; then
      log_error "WEBUI_SECRET_KEY_LENGTH must be a positive integer."
      exit 1
    fi
    head -c "$WEBUI_SECRET_KEY_LENGTH" /dev/random | base64 > "$KEY_FILE"
    log_info "New WEBUI_SECRET_KEY generated and saved to ${KEY_FILE}"
  else
    log_info "Loading WEBUI_SECRET_KEY from ${KEY_FILE}"
  fi

  WEBUI_SECRET_KEY=$(cat "$KEY_FILE")
else
  log_info "Using WEBUI_SECRET_KEY from environment variable"
fi

# ── Database initialization and migration check ──────────────────────────────
log_info "Checking database status..."

DATA_DIR="${DATA_DIR:-/app/backend/data}"
mkdir -p "$DATA_DIR"

# Check for SQLite database
if [[ -f "${DATA_DIR}/webui.db" ]]; then
    DB_SIZE=$(du -h "${DATA_DIR}/webui.db" | cut -f1)
    log_info "Found existing database: ${DATA_DIR}/webui.db (${DB_SIZE})"
else
    log_info "No existing database found, will create on first run"
fi

# ── Backup check on startup (if backup restoration is enabled) ─────────────────
if [[ "${ENABLE_BACKUP_RESTORE_ON_STARTUP:-false}" == "true" ]]; then
    log_info "Checking for backup to restore..."
    if [[ -f "/tmp/restore/latest.sqlite" ]]; then
        log_info "Found backup, restoring database..."
        cp "/tmp/restore/latest.sqlite" "${DATA_DIR}/webui.db"
        log_info "Database restored from backup"
    fi
fi

# ── Ollama (bundled Docker image) ────────────────────────────────────────────

if [[ "${USE_OLLAMA_DOCKER,,}" == "true" ]]; then
  log_info "Starting bundled ollama serve..."
  ollama serve &
  OLLAMA_PID=$!
  log_info "Ollama started with PID: ${OLLAMA_PID}"
fi

# ── CUDA library paths ──────────────────────────────────────────────────────

if [[ "${USE_CUDA_DOCKER,,}" == "true" ]]; then
  log_info "CUDA enabled — extending LD_LIBRARY_PATH for torch/cudnn libraries."
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:/usr/local/lib/python3.11/site-packages/torch/lib:/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib"
fi

# ── HuggingFace Space deployment ─────────────────────────────────────────────

if [[ -n "${SPACE_ID:-}" ]]; then
  log_info "Configuring for HuggingFace Space deployment..."

  if [[ -n "${ADMIN_USER_EMAIL:-}" && -n "${ADMIN_USER_PASSWORD:-}" ]]; then
    log_info "Creating admin user for Space..."
    WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-}" \
      uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips "${FORWARDED_ALLOW_IPS:-*}" &
    webui_pid=$!

    log_info "Waiting for server to become healthy..."
    until curl -sf "http://localhost:${PORT}/health" > /dev/null 2>&1; do
      sleep 1
    done

    log_info "Registering admin user..."
    curl -sS -X POST "http://localhost:${PORT}/api/v1/auths/signup" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"${ADMIN_USER_EMAIL}\", \"password\": \"${ADMIN_USER_PASSWORD}\", \"name\": \"Admin\"}"

    log_info "Restarting server..."
    kill "$webui_pid"
    wait "$webui_pid" 2>/dev/null || true
  fi

  export WEBUI_URL="${SPACE_HOST}"
fi

# ── Health monitoring setup ───────────────────────────────────────────────────
HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-30}"
MAX_RESTART_ATTEMPTS="${MAX_RESTART_ATTEMPTS:-5}"
RESTART_COOLDOWN="${RESTART_COOLDOWN:-60}"

# Start background health monitor
start_health_monitor() {
    log_info "Starting health monitoring (interval: ${HEALTH_CHECK_INTERVAL}s)"
    
    (
        while true; do
            sleep "$HEALTH_CHECK_INTERVAL"
            
            # Check if server is responding
            if ! curl -sf "http://localhost:${PORT}/health" > /dev/null 2>&1; then
                log_warn "Health check failed, checking readiness..."
                
                # Try readiness endpoint
                if curl -sf "http://localhost:${PORT}/ready" > /dev/null 2>&1; then
                    log_info "Server is ready but not responding to health"
                else
                    log_error "Server health check failed"
                    # Write to crash marker for monitoring
                    echo "$(date +%s)" > /tmp/health_check_failed
                fi
            else
                # Clear crash marker if exists
                rm -f /tmp/health_check_failed
            fi
        done
    ) &
    
    HEALTH_MONITOR_PID=$!
    log_info "Health monitor started with PID: ${HEALTH_MONITOR_PID}"
}

# Start health monitor in background
start_health_monitor

# ── Launch uvicorn ───────────────────────────────────────────────────────────

PYTHON_CMD=$(command -v python3 || command -v python)
UVICORN_WORKERS="${UVICORN_WORKERS:-1}"

# Determine worker count based on CPU cores
if [[ -f /proc/cpuinfo ]]; then
    CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
    UVICORN_WORKERS="${UVICORN_WORKERS:-$((CPU_CORES < 4 ? 1 : 2))}"
fi

log_info "Starting uvicorn with ${UVICORN_WORKERS} worker(s)"

if [[ "$#" -gt 0 ]]; then
  ARGS=("$@")
else
  ARGS=(--workers "$UVICORN_WORKERS")
fi

# Handle graceful shutdown
shutdown_handler() {
    log_info "Received shutdown signal, gracefully stopping..."
    pkill -f "uvicorn open_webui.main:app" 2>/dev/null || true
    wait 2>/dev/null || true
    log_info "Shutdown complete"
    exit 0
}

trap shutdown_handler SIGTERM SIGINT

# Launch the server
exec env WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-}" \
  "$PYTHON_CMD" -m uvicorn open_webui.main:app \
    --host "$HOST" \
    --port "$PORT" \
    --forwarded-allow-ips "${FORWARDED_ALLOW_IPS:-*}" \
    --log-level "${LOG_LEVEL:-info}" \
    "${ARGS[@]}"
