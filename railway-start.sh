#!/usr/bin/env bash
# =============================================================================
# Open Connect - Railway Production Startup Script
# =============================================================================
# This script handles:
# - Data persistence and backup restoration
# - Secret key management
# - Database initialization
# - Health monitoring
# - Graceful shutdown
# - Self-healing capabilities
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}"
DATA_DIR="${DATA_DIR:-/app/backend/data}"

# Logging
LOG_FILE="${LOG_FILE:-/app/backend/startup.log}"
mkdir -p "$(dirname "$LOG_FILE")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================

log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local color="${NC}"
    
    case "$level" in
        ERROR)  color="${RED}";   level="ERROR" ;;
        WARN)   color="${YELLOW}"; level="WARN"  ;;
        SUCCESS) color="${GREEN}";  level="SUCCESS" ;;
        INFO)    color="${BLUE}";  level="INFO" ;;
    esac
    
    echo -e "${color}[${timestamp}] [${level}] ${message}${NC}" | tee -a "$LOG_FILE" >&2
}

log_info()    { log "INFO" "$1"; }
log_success() { log "SUCCESS" "$1"; }
log_warn()    { log "WARN" "$1"; }
log_error()   { log "ERROR" "$1"; }

# =============================================================================
# Trap Handler for Clean Shutdown
# =============================================================================

cleanup() {
    local exit_code=$?
    log_info "Received shutdown signal, cleaning up..."
    
    # Signal uvicorn to stop gracefully
    if [[ -n "${UVICORN_PID:-}" ]]; then
        log_info "Stopping uvicorn (PID: ${UVICORN_PID})..."
        kill -TERM "$UVICORN_PID" 2>/dev/null || true
        wait "$UVICORN_PID" 2>/dev/null || true
    fi
    
    log_info "Cleanup complete. Exiting with code: $exit_code"
    exit "$exit_code"
}

trap cleanup SIGTERM SIGINT SIGQUIT SIGHUP

# =============================================================================
# Environment Variable Normalization
# =============================================================================

: "${WEB_LOADER_ENGINE:=}" 
: "${USE_OLLAMA_DOCKER:=}" 
: "${USE_CUDA_DOCKER:=}"
: "${ENV:=prod}"
: "${PORT:=8080}"
: "${HOST:=0.0.0.0}"
: "${UVICORN_WORKERS:=1}"

# =============================================================================
# Banner
# =============================================================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}     ${BLUE}██████╗ ██████╗ ███████╗██╗   ██╗██╗  ██╗${NC}             "
echo -e "${GREEN}║${NC}     ${BLUE}██╔══██╗██╔══██╗██╔════╝██║   ██║╚██╗██╔╝${NC}             "
echo -e "${GREEN}║${NC}     ${BLUE}██████╔╝██████╔╝███████╗██║   ██║ ╚███╔╝ ${NC}             "
echo -e "${GREEN}║${NC}     ${BLUE}██╔══██╗██╔══██╗╚════██║██║   ██║ ██╔██╗${NC}             "
echo -e "${GREEN}║${NC}     ${BLUE}██║  ██║██║  ██║███████║╚██████╔╝██╔╝ ██╗${NC}            "
echo -e "${GREEN}║${NC}     ${BLUE}╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝${NC}            "
echo -e "${GREEN}║${NC}                  ${BLUE}C O N N E C T${NC}                             "
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# Startup Sequence
# =============================================================================

log_info "=========================================="
log_info "Open Connect - Railway Production Startup"
log_info "=========================================="
log_info "Version: ${APP_VERSION:-unknown}"
log_info "Build: ${BUILD_HASH:-dev}"
log_info "Environment: ${ENV}"
log_info "Python: $(python3 --version 2>&1)"
log_info "Hostname: ${HOSTNAME:-unknown}"
log_info "Data Directory: ${DATA_DIR}"
log_info "=========================================="
echo ""

# =============================================================================
# 1. Data Directory Setup
# =============================================================================

log_info "Step 1/8: Setting up data directory..."

mkdir -p "${DATA_DIR}"
mkdir -p "${DATA_DIR}/uploads"
mkdir -p "${DATA_DIR}/cache"
mkdir -p "${DATA_DIR}/cache/embedding"
mkdir -p "${DATA_DIR}/cache/whisper"
mkdir -p "${DATA_DIR}/knowledge"
mkdir -p "${DATA_DIR}/chat_history"
mkdir -p "${DATA_DIR}/memories"
mkdir -p "${DATA_DIR}/notes"

# Ensure proper permissions
chmod -R 755 "${DATA_DIR}" 2>/dev/null || true

log_success "Data directory setup complete"

# =============================================================================
# 2. Backup Restoration Check
# =============================================================================

log_info "Step 2/8: Checking for backup restoration..."

RESTORE_DIR="${RESTORE_DIR:-/tmp/restore}"
RESTORE_ENABLED="${ENABLE_BACKUP_RESTORE_ON_STARTUP:-false}"

if [[ "$RESTORE_ENABLED" == "true" ]] || [[ -d "$RESTORE_DIR" ]]; then
    log_info "Backup restoration is enabled"
    
    # Check for backup files
    if [[ -f "${RESTORE_DIR}/webui.db" ]]; then
        log_info "Found backup database, verifying..."
        
        # Create backup of current database if exists
        if [[ -f "${DATA_DIR}/webui.db" ]]; then
            cp "${DATA_DIR}/webui.db" "${DATA_DIR}/webui.db.backup-$(date +%s)"
            log_info "Current database backed up"
        fi
        
        # Restore from backup
        cp "${RESTORE_DIR}/webui.db" "${DATA_DIR}/webui.db"
        
        # Verify restored database
        if python3 -c "import sqlite3; sqlite3.connect('${DATA_DIR}/webui.db').close()" 2>/dev/null; then
            log_success "Database restored from backup"
        else
            log_error "Backup restoration failed - database may be corrupted"
            # Restore backup
            if [[ -f "${DATA_DIR}/webui.db.backup-"* ]]; then
                LATEST_BACKUP=$(ls -t "${DATA_DIR}"/webui.db.backup-* | head -1)
                cp "$LATEST_BACKUP" "${DATA_DIR}/webui.db"
                log_warn "Restored from latest backup"
            fi
        fi
    fi
    
    # Restore other files
    [[ -f "${RESTORE_DIR}/.webui_secret_key" ]] && \
        cp "${RESTORE_DIR}/.webui_secret_key" "${BACKEND_DIR}/.webui_secret_key" && \
        log_success "Secret key restored"
    
    # Restore uploads if backup exists
    if [[ -d "${RESTORE_DIR}/uploads" ]]; then
        cp -r "${RESTORE_DIR}/uploads"/* "${DATA_DIR}/uploads/" 2>/dev/null || true
        log_success "Uploads restored"
    fi
    
    # Restore knowledge base
    if [[ -d "${RESTORE_DIR}/knowledge" ]]; then
        cp -r "${RESTORE_DIR}/knowledge"/* "${DATA_DIR}/knowledge/" 2>/dev/null || true
        log_success "Knowledge base restored"
    fi
else
    log_info "Backup restoration skipped (no restore directory found)"
fi

# =============================================================================
# 3. Secret Key Management
# =============================================================================

log_info "Step 3/8: Setting up secret key..."

KEY_FILE="${WEBUI_SECRET_KEY_FILE:-${BACKEND_DIR}/.webui_secret_key}"
WEBUI_SECRET_KEY_LENGTH="${WEBUI_SECRET_KEY_LENGTH:-32}"

if [[ -z "${WEBUI_SECRET_KEY:-}" ]] && [[ -z "${WEBUI_JWT_SECRET_KEY:-}" ]]; then
    log_info "No WEBUI_SECRET_KEY in environment, checking file..."
    
    if [[ ! -f "$KEY_FILE" ]]; then
        log_info "Generating new WEBUI_SECRET_KEY..."
        head -c "$WEBUI_SECRET_KEY_LENGTH" /dev/random | base64 > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        log_success "New secret key generated and saved to ${KEY_FILE}"
    else
        log_info "Loading existing secret key from ${KEY_FILE}"
    fi
    
    WEBUI_SECRET_KEY=$(cat "$KEY_FILE")
    export WEBUI_SECRET_KEY
    log_success "Secret key ready"
else
    log_info "Using WEBUI_SECRET_KEY from environment"
fi

# =============================================================================
# 4. Database Initialization
# =============================================================================

log_info "Step 4/8: Checking database..."

DB_FILE="${DATA_DIR}/webui.db"

if [[ -f "$DB_FILE" ]]; then
    DB_SIZE=$(du -h "$DB_FILE" | cut -f1)
    DB_TABLES=$(sqlite3 "$DB_FILE" ".tables" 2>/dev/null | wc -w || echo "0")
    log_success "Database found: ${DB_SIZE}, ${DB_TABLES} tables"
    
    # Verify database integrity
    if sqlite3 "$DB_FILE" "PRAGMA integrity_check;" 2>/dev/null | grep -q "ok"; then
        log_success "Database integrity verified"
    else
        log_warn "Database integrity check failed - attempting repair"
        sqlite3 "$DB_FILE" "REINDEX;" 2>/dev/null || true
    fi
else
    log_info "No database found - will be created on first request"
fi

# =============================================================================
# 5. Ollama Setup (if enabled)
# =============================================================================

log_info "Step 5/8: Setting up Ollama..."

if [[ "${USE_OLLAMA_DOCKER,,}" == "true" ]]; then
    log_info "Starting bundled Ollama service..."
    
    if command -v ollama &>/dev/null; then
        ollama serve &
        OLLAMA_PID=$!
        log_success "Ollama started (PID: ${OLLAMA_PID})"
        
        # Wait for Ollama to be ready
        local attempts=0
        while ! curl -sf http://localhost:11434/api/tags &>/dev/null; do
            ((attempts++))
            if ((attempts > 30)); then
                log_warn "Ollama failed to start within timeout"
                break
            fi
            sleep 1
        done
        
        if ((attempts <= 30)); then
            log_success "Ollama is ready"
        fi
    else
        log_warn "Ollama not found in PATH"
    fi
fi

# =============================================================================
# 6. CUDA Setup (if enabled)
# =============================================================================

log_info "Step 6/8: Setting up CUDA..."

if [[ "${USE_CUDA_DOCKER,,}" == "true" ]]; then
    log_info "CUDA enabled - configuring library paths"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:/usr/local/lib/python3.11/site-packages/torch/lib"
    log_success "CUDA configuration complete"
fi

# =============================================================================
# 7. Health Monitoring Setup
# =============================================================================

log_info "Step 7/8: Starting health monitoring..."

HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-30}"

start_health_monitor() {
    log_info "Health monitor started (interval: ${HEALTH_CHECK_INTERVAL}s)"
    
    (
        while true; do
            sleep "$HEALTH_CHECK_INTERVAL"
            
            if ! curl -sf "http://localhost:${PORT}/health" &>/dev/null; then
                log_warn "Health check failed"
                echo "$(date +%s)" > /tmp/health_check_failed
            else
                rm -f /tmp/health_check_failed
            fi
        done
    ) &
}

start_health_monitor

# =============================================================================
# 8. Start Application
# =============================================================================

log_info "Step 8/8: Starting application..."

PYTHON_CMD=$(command -v python3 || command -v python)
UVICORN_WORKERS="${UVICORN_WORKERS:-1}"

# Auto-detect CPU cores for optimal worker count
if [[ -f /proc/cpuinfo ]]; then
    CPU_CORES=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
    if [[ "$UVICORN_WORKERS" == "1" ]] && ((CPU_CORES >= 4)); then
        UVICORN_WORKERS=2
    fi
fi

log_info "Starting uvicorn with ${UVICORN_WORKERS} worker(s)"

# Export secret key for uvicorn
export WEBUI_SECRET_KEY

# Start uvicorn in background and capture PID
"$PYTHON_CMD" -m uvicorn open_webui.main:app \
    --host "$HOST" \
    --port "$PORT" \
    --forwarded-allow-ips "${FORWARDED_ALLOW_IPS:-*}" \
    --log-level "${LOG_LEVEL:-info}" \
    --workers "$UVICORN_WORKERS" &
    
UVICORN_PID=$!

log_success "Application started (PID: ${UVICORN_PID})"

# =============================================================================
# Wait for Application to be Ready
# =============================================================================

log_info "Waiting for application to be ready..."

local max_attempts=60
local attempt=0

while ((attempt < max_attempts)); do
    if curl -sf "http://localhost:${PORT}/health" &>/dev/null; then
        log_success "Application is ready!"
        echo ""
        log_info "=========================================="
        log_success "Open Connect is running!"
        log_info "=========================================="
        log_info "Health: http://localhost:${PORT}/health"
        log_info "API:    http://localhost:${PORT}/api/v1"
        log_info "Docs:   http://localhost:${PORT}/docs"
        log_info "=========================================="
        echo ""
        
        # Wait for uvicorn to finish
        wait "$UVICORN_PID"
        exit $?
    fi
    
    # Check if process is still running
    if ! kill -0 "$UVICORN_PID" 2>/dev/null; then
        log_error "Application process died unexpectedly"
        exit 1
    fi
    
    ((attempt++))
    sleep 1
    
    # Progress indicator every 10 seconds
    if ((attempt % 10 == 0)); then
        log_info "Still starting... (${attempt}/${max_attempts}s)"
    fi
done

log_error "Application failed to start within ${max_attempts} seconds"
exit 1
