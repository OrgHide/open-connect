#!/bin/bash
# Open Connect Restore Script - Production Ready
# This script restores data from a backup with verification and rollback support

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATA_DIR="${DATA_DIR:-./backend/data}"
BACKEND_DIR="${BACKEND_DIR:-./backend}"

# Supabase Configuration
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
SUPABASE_BUCKET="${SUPABASE_BUCKET:-open-connect-backups}"

# Restore options
DRY_RUN="${DRY_RUN:-false}"
SKIP_PROMPT="${SKIP_PROMPT:-false}"
VERIFY_CHECKSUM="${VERIFY_CHECKSUM:-true}"
BACKUP_BEFORE_RESTORE="${BACKUP_BEFORE_RESTORE:-true}"

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

log_warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $1"
}

log_success() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $1"
}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}  Open Connect Restore Script${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo ""
}

print_usage() {
    echo "Usage: $0 [OPTIONS] [BACKUP_FILE]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run           Show what would be restored without actually restoring"
    echo "  -y, --yes               Skip confirmation prompts"
    echo "  --no-checksum          Skip checksum verification"
    echo "  --no-backup            Skip backup before restore"
    echo "  --from-supabase        Download latest backup from Supabase"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ./backups/open-connect_backup_20240101_120000.tar.gz"
    echo "  $0 --from-supabase"
    echo "  $0 --dry-run ./backups/latest.tar.gz"
    echo ""
    echo "Available backups in ${BACKUP_DIR}:"
    ls -la "${BACKUP_DIR}"/open-connect_backup_*.tar.gz 2>/dev/null | tail -10 || echo "No backups found"
}

# Parse arguments
POSITIONAL_ARGS=()
FROM_SUPABASE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -y|--yes)
            SKIP_PROMPT=true
            shift
            ;;
        --no-checksum)
            VERIFY_CHECKSUM=false
            shift
            ;;
        --no-backup)
            BACKUP_BEFORE_RESTORE=false
            shift
            ;;
        --from-supabase)
            FROM_SUPABASE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

print_header

# ── Download from Supabase ──────────────────────────────────────────────────────
if [ "$FROM_SUPABASE" = true ]; then
    log "📥 Downloading latest backup from Supabase..."
    
    if [ -z "$SUPABASE_PROJECT_REF" ] || [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
        log_error "Supabase credentials not configured"
        log "Set SUPABASE_PROJECT_REF and SUPABASE_ACCESS_TOKEN environment variables"
        exit 1
    fi
    
    # Get list of backups
    BACKUP_LIST=$(curl -s \
        "https://api.supabase.com/v1/storage/${SUPABASE_BUCKET}/objects/list" \
        -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
        -d '{"prefix": "backups/"}' 2>/dev/null || echo "[]")
    
    LATEST_BACKUP=$(echo "${BACKUP_LIST}" | jq -r '.[-1].name' 2>/dev/null)
    
    if [ -z "$LATEST_BACKUP" ] || [ "$LATEST_BACKUP" = "null" ]; then
        log_error "No backups found in Supabase"
        exit 1
    fi
    
    log "Found latest backup: ${LATEST_BACKUP}"
    
    # Download the backup
    mkdir -p "${BACKUP_DIR}"
    curl -s -L \
        "https://api.supabase.com/v1/storage/${SUPABASE_BUCKET}/objects/download/${LATEST_BACKUP}" \
        -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
        -o "${BACKUP_DIR}/${LATEST_BACKUP}"
    
    BACKUP_FILE="${BACKUP_DIR}/${LATEST_BACKUP}"
    log_success "Backup downloaded to ${BACKUP_FILE}"
    
elif [ $# -eq 0 ]; then
    # No backup file provided, try latest
    if [ -f "${BACKUP_DIR}/latest.tar.gz" ]; then
        BACKUP_FILE="${BACKUP_DIR}/latest.tar.gz"
        log "Using latest backup: ${BACKUP_FILE}"
    elif [ -f "${BACKUP_DIR}/latest-backup.tar.gz" ]; then
        BACKUP_FILE="${BACKUP_DIR}/latest-backup.tar.gz"
        log "Using latest backup: ${BACKUP_FILE}"
    else
        log_error "No backup file specified and no latest backup found"
        print_usage
        exit 1
    fi
else
    BACKUP_FILE="$1"
fi

# ── Validate backup file ────────────────────────────────────────────────────────
if [ ! -f "${BACKUP_FILE}" ]; then
    log_error "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Verify backup integrity
log "Verifying backup integrity..."
if ! tar -tzf "${BACKUP_FILE}" > /dev/null 2>&1; then
    log_error "Backup file is corrupted or invalid"
    exit 1
fi
log_success "Backup file integrity verified"

# ── Create temporary extraction directory ───────────────────────────────────────
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

log "Extracting backup to temporary directory..."
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Find the extracted backup directory
BACKUP_PATH=$(find "${TEMP_DIR}" -maxdepth 1 -type d -name "open-connect_backup_*" | head -1)
BACKUP_NAME=$(basename "${BACKUP_PATH}")

if [ -z "${BACKUP_PATH}" ]; then
    # Try alternate naming pattern
    BACKUP_PATH=$(find "${TEMP_DIR}" -maxdepth 1 -type d -name "*backup*" | head -1)
    BACKUP_NAME=$(basename "${BACKUP_PATH}")
fi

if [ -z "${BACKUP_PATH}" ]; then
    log_error "Invalid backup format - could not find backup directory"
    exit 1
fi

log_success "Backup extracted: ${BACKUP_NAME}"

# ── Show backup information ─────────────────────────────────────────────────────
echo ""
echo "Backup Information:"
echo "------------------"

if [ -f "${BACKUP_PATH}/metadata.json" ]; then
    cat "${BACKUP_PATH}/metadata.json" | jq '.' 2>/dev/null || cat "${BACKUP_PATH}/metadata.json"
    echo ""
fi

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "Backup file: ${BACKUP_FILE}"
echo "Backup size: ${BACKUP_SIZE}"
echo "Extracted to: ${BACKUP_PATH}"
echo ""

# ── List restoreable items ───────────────────────────────────────────────────────
echo "Items to restore:"
echo "-----------------"

[ -f "${BACKUP_PATH}/database/webui.db" ] && echo "  ✓ Database (webui.db)"
[ -d "${BACKUP_PATH}/uploads" ] && echo "  ✓ User uploads"
[ -d "${BACKUP_PATH}/knowledge" ] && echo "  ✓ Knowledge base"
[ -d "${BACKUP_PATH}/chat_history" ] && echo "  ✓ Chat history"
[ -f "${BACKUP_PATH}/.webui_secret_key" ] && echo "  ✓ Secret key"
[ -f "${BACKUP_PATH}/.env.backup" ] && echo "  ✓ Configuration"
[ -d "${BACKUP_PATH}/memories" ] && echo "  ✓ Memories"
[ -d "${BACKUP_PATH}/notes" ] && echo "  ✓ Notes"

echo ""

# ── Dry run mode ───────────────────────────────────────────────────────────────
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}=== DRY RUN MODE - No changes will be made ===${NC}"
    echo ""
    echo "Would restore:"
    
    [ -f "${BACKUP_PATH}/database/webui.db" ] && echo "  → ${DATA_DIR}/webui.db"
    [ -d "${BACKUP_PATH}/uploads" ] && echo "  → ${DATA_DIR}/uploads/"
    [ -d "${BACKUP_PATH}/knowledge" ] && echo "  → ${DATA_DIR}/knowledge/"
    [ -d "${BACKUP_PATH}/chat_history" ] && echo "  → ${DATA_DIR}/chat_history/"
    [ -f "${BACKUP_PATH}/.webui_secret_key" ] && echo "  → ${BACKEND_DIR}/.webui_secret_key"
    
    exit 0
fi

# ── Confirmation prompt ────────────────────────────────────────────────────────
if [ "$SKIP_PROMPT" != true ]; then
    echo -e "${YELLOW}⚠️  This will overwrite existing data.${NC}"
    read -p "Continue with restore? (y/N) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restore cancelled by user"
        exit 0
    fi
fi

# ── Backup current data before restore ──────────────────────────────────────────
if [ "$BACKUP_BEFORE_RESTORE" = true ]; then
    log "Creating backup of current data before restore..."
    
    PRE_RESTORE_BACKUP="pre-restore-$(date +%Y%m%d_%H%M%S)"
    PRE_RESTORE_DIR="/tmp/${PRE_RESTORE_BACKUP}"
    mkdir -p "${PRE_RESTORE_DIR}"
    
    # Backup existing data
    [ -f "${DATA_DIR}/webui.db" ] && cp "${DATA_DIR}/webui.db" "${PRE_RESTORE_DIR}/webui.db"
    [ -d "${DATA_DIR}/uploads" ] && cp -r "${DATA_DIR}/uploads" "${PRE_RESTORE_DIR}/" 2>/dev/null || true
    [ -d "${DATA_DIR}/knowledge" ] && cp -r "${DATA_DIR}/knowledge" "${PRE_RESTORE_DIR}/" 2>/dev/null || true
    [ -f "${BACKEND_DIR}/.webui_secret_key" ] && cp "${BACKEND_DIR}/.webui_secret_key" "${PRE_RESTORE_DIR}/" 2>/dev/null || true
    
    # Create rollback script
    cat > "${PRE_RESTORE_DIR}/rollback.sh" << 'ROLLBACK'
#!/bin/bash
echo "Rolling back restore..."
PRE_RESTORE_DIR="$(dirname "$0")"
DATA_DIR="${DATA_DIR:-./backend/data}"
BACKEND_DIR="${BACKEND_DIR:-./backend}"

[ -f "${PRE_RESTORE_DIR}/webui.db" ] && cp "${PRE_RESTORE_DIR}/webui.db" "${DATA_DIR}/webui.db"
[ -d "${PRE_RESTORE_DIR}/uploads" ] && cp -r "${PRE_RESTORE_DIR}/uploads" "${DATA_DIR}/" 2>/dev/null || true
[ -d "${PRE_RESTORE_DIR}/knowledge" ] && cp -r "${PRE_RESTORE_DIR}/knowledge" "${DATA_DIR}/" 2>/dev/null || true
[ -f "${PRE_RESTORE_DIR}/.webui_secret_key" ] && cp "${PRE_RESTORE_DIR}/.webui_secret_key" "${BACKEND_DIR}/" 2>/dev/null || true

echo "Rollback complete. Restart the application."
ROLLBACK
    chmod +x "${PRE_RESTORE_DIR}/rollback.sh"
    
    tar -czf "/tmp/${PRE_RESTORE_BACKUP}.tar.gz" -C /tmp "${PRE_RESTORE_BACKUP}"
    rm -rf "${PRE_RESTORE_DIR}"
    
    log_success "Pre-restore backup created: /tmp/${PRE_RESTORE_BACKUP}.tar.gz"
    log "To rollback: tar -xzf /tmp/${PRE_RESTORE_BACKUP}.tar.gz -C /tmp && /tmp/${PRE_RESTORE_BACKUP}/rollback.sh"
    echo ""
fi

# ── Start restore process ──────────────────────────────────────────────────────
log "Starting restore process..."
echo ""

# Create directories
mkdir -p "${DATA_DIR}"
mkdir -p "${BACKEND_DIR}"

# Restore 1: Database
echo "1. Restoring database..."
if [ -f "${BACKUP_PATH}/database/webui.db" ]; then
    if [ "$VERIFY_CHECKSUM" = true ] && [ -f "${BACKUP_PATH}/database/webui.db.md5" ]; then
        MD5_ORIG=$(cat "${BACKUP_PATH}/database/webui.db.md5" | cut -d' ' -f1)
        MD5_RESTORE=$(md5sum "${BACKUP_PATH}/database/webui.db" | cut -d' ' -f1)
        
        if [ "$MD5_ORIG" = "$MD5_RESTORE" ]; then
            log_success "Database checksum verified"
        else
            log_error "Database checksum mismatch! Original: ${MD5_ORIG}, Restored: ${MD5_RESTORE}"
            exit 1
        fi
    fi
    
    cp "${BACKUP_PATH}/database/webui.db" "${DATA_DIR}/webui.db"
    log_success "Database restored to ${DATA_DIR}/webui.db"
else
    log_warn "No database found in backup"
fi

# Restore 2: User uploads
echo "2. Restoring user uploads..."
if [ -d "${BACKUP_PATH}/uploads" ]; then
    if [ -d "${BACKUP_PATH}/uploads.tar.gz" ]; then
        tar -xzf "${BACKUP_PATH}/uploads.tar.gz" -C "${DATA_DIR}"
    else
        cp -r "${BACKUP_PATH}/uploads" "${DATA_DIR}/uploads"
    fi
    log_success "User uploads restored"
else
    log_warn "No uploads found in backup"
fi

# Restore 3: Knowledge base
echo "3. Restoring knowledge base..."
if [ -d "${BACKUP_PATH}/knowledge" ]; then
    if [ -f "${BACKUP_PATH}/knowledge.tar.gz" ]; then
        tar -xzf "${BACKUP_PATH}/knowledge.tar.gz" -C "${DATA_DIR}"
    else
        cp -r "${BACKUP_PATH}/knowledge" "${DATA_DIR}/knowledge"
    fi
    log_success "Knowledge base restored"
else
    log_warn "No knowledge base found in backup"
fi

# Restore 4: Chat history
echo "4. Restoring chat history..."
if [ -d "${BACKUP_PATH}/chat_history" ]; then
    if [ -f "${BACKUP_PATH}/chat_history.tar.gz" ]; then
        tar -xzf "${BACKUP_PATH}/chat_history.tar.gz" -C "${DATA_DIR}"
    else
        cp -r "${BACKUP_PATH}/chat_history" "${DATA_DIR}/chat_history"
    fi
    log_success "Chat history restored"
else
    log_warn "No chat history found in backup"
fi

# Restore 5: Cache
echo "5. Restoring cache (embedding models)..."
if [ -d "${BACKUP_PATH}/cache" ]; then
    cp -r "${BACKUP_PATH}/cache/embedding" "${DATA_DIR}/cache/" 2>/dev/null || true
    log_success "Cache restored"
else
    log_warn "No cache found in backup (can be re-downloaded)"
fi

# Restore 6: Secret key
echo "6. Restoring secret key..."
if [ -f "${BACKUP_PATH}/.webui_secret_key" ]; then
    cp "${BACKUP_PATH}/.webui_secret_key" "${BACKEND_DIR}/.webui_secret_key"
    log_success "Secret key restored"
else
    log_warn "No secret key found in backup"
fi

# Restore 7: Configuration
echo "7. Restoring configuration..."
if [ -f "${BACKUP_PATH}/.env.backup" ]; then
    cp "${BACKUP_PATH}/.env.backup" "${BACKEND_DIR}/.env.restore"
    log_success "Configuration backed up as .env.restore"
    log "⚠️ Please manually merge sensitive values from .env.restore into .env"
else
    log_warn "No configuration found in backup"
fi

# Restore 8: Memories and Notes
echo "8. Restoring memories and notes..."
[ -d "${BACKUP_PATH}/memories" ] && cp -r "${BACKUP_PATH}/memories" "${DATA_DIR}/" 2>/dev/null || true
[ -d "${BACKUP_PATH}/notes" ] && cp -r "${BACKUP_PATH}/notes" "${DATA_DIR}/" 2>/dev/null || true

# Restore 9: Workspace resources
echo "9. Restoring workspace resources..."
mkdir -p "${BACKEND_DIR}/open_webui"
[ -d "${BACKUP_PATH}/workspace_resources/plugins" ] && cp -r "${BACKUP_PATH}/workspace_resources/plugins" "${BACKEND_DIR}/open_webui/" 2>/dev/null || true
[ -d "${BACKUP_PATH}/workspace_resources/skills" ] && cp -r "${BACKUP_PATH}/workspace_resources/skills" "${BACKEND_DIR}/open_webui/" 2>/dev/null || true
[ -d "${BACKUP_PATH}/workspace_resources/pipelines" ] && cp -r "${BACKUP_PATH}/workspace_resources/pipelines" "${BACKEND_DIR}/open_webui/" 2>/dev/null || true
if [ -d "${BACKUP_PATH}/workspace_resources/integrations" ]; then
    mkdir -p "${BACKEND_DIR}/open_webui/integrations"
    [ -f "${BACKUP_PATH}/workspace_resources/integrations/.agents.json" ] && cp "${BACKUP_PATH}/workspace_resources/integrations/.agents.json" "${BACKEND_DIR}/open_webui/integrations/.agents.json" 2>/dev/null || true
    [ -f "${BACKUP_PATH}/workspace_resources/integrations/.connectors.json" ] && cp "${BACKUP_PATH}/workspace_resources/integrations/.connectors.json" "${BACKEND_DIR}/open_webui/integrations/.connectors.json" 2>/dev/null || true
fi

# Verify restore
echo ""
echo "Verifying restored data..."
if [ -f "${DATA_DIR}/webui.db" ]; then
    DB_SIZE=$(du -h "${DATA_DIR}/webui.db" | cut -f1)
    DB_TABLES=$(sqlite3 "${DATA_DIR}/webui.db" ".tables" 2>/dev/null | wc -w)
    log_success "Database verified: ${DB_SIZE}, ${DB_TABLES} tables"
fi

# ── Summary ─────────────────────────────────────────────────────────────────────
echo ""
echo "=============================================="
log_success "Restore completed successfully!"
echo "=============================================="
echo ""
echo "⚠️  IMPORTANT STEPS:"
echo "1. Restart the application to apply changes"
echo "2. Verify all API keys are set correctly"
echo "3. Check that the database is accessible"
echo "4. Test the application functionality"
echo ""
echo "📝 Rollback instructions:"
if [ "$BACKUP_BEFORE_RESTORE" = true ]; then
    echo "   tar -xzf /tmp/${PRE_RESTORE_BACKUP}.tar.gz -C /tmp"
    echo "   /tmp/${PRE_RESTORE_BACKUP}/rollback.sh"
else
    echo "   ⚠️ No rollback backup created"
fi
echo ""

exit 0
