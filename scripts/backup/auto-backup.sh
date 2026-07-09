#!/bin/bash
# Open Connect Auto-Backup Script
# This script performs automated backups with retention management
# Run via cron: 0 2 * * * /path/to/scripts/backup/auto-backup.sh

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
BACKUP_NAME="open-connect_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Railway Data Directory (mounted volume)
DATA_DIR="${RAILWAY_VOLUME_MOUNT_DIR:-/app/backend/data}"
BACKEND_DIR="${BACKEND_DIR:-/app/backend}"

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Create backup directory
mkdir -p "${BACKUP_PATH}"

log "=============================================="
log "Open Connect Auto-Backup Script"
log "=============================================="
log "Backup Location: ${BACKUP_PATH}"
log "Retention: ${RETENTION_DAYS} days"
log ""

# Track backup status
BACKUP_STATUS=0

# Backup 1: Database
log "1. Backing up database..."
if [ -f "${DATA_DIR}/webui.db" ]; then
    mkdir -p "${BACKUP_PATH}/database"
    cp "${DATA_DIR}/webui.db" "${BACKUP_PATH}/database/webui.db"
    
    # Get database size
    DB_SIZE=$(du -h "${DATA_DIR}/webui.db" | cut -f1)
    log "   ✓ Database backed up: ${DB_SIZE}"
else
    log "   ⚠ No database found at ${DATA_DIR}/webui.db"
    BACKUP_STATUS=1
fi

# Backup 2: User uploads and files
log "2. Backing up user uploads..."
if [ -d "${DATA_DIR}/uploads" ]; then
    mkdir -p "${BACKUP_PATH}/uploads"
    cp -r "${DATA_DIR}/uploads" "${BACKUP_PATH}/uploads"
    
    UPLOADS_SIZE=$(du -sh "${DATA_DIR}/uploads" | cut -f1)
    log "   ✓ User uploads backed up: ${UPLOADS_SIZE}"
else
    log "   ⚠ No uploads directory found"
fi

# Backup 3: Knowledge base
log "3. Backing up knowledge base..."
if [ -d "${DATA_DIR}/knowledge" ]; then
    mkdir -p "${BACKUP_PATH}/knowledge"
    cp -r "${DATA_DIR}/knowledge" "${BACKUP_PATH}/knowledge"
    
    KNOWLEDGE_SIZE=$(du -sh "${DATA_DIR}/knowledge" | cut -f1)
    log "   ✓ Knowledge base backed up: ${KNOWLEDGE_SIZE}"
else
    log "   ⚠ No knowledge base found"
fi

# Backup 4: Secret key
log "4. Backing up secret key..."
if [ -f "${BACKEND_DIR}/.webui_secret_key" ]; then
    cp "${BACKEND_DIR}/.webui_secret_key" "${BACKUP_PATH}/.webui_secret_key"
    log "   ✓ Secret key backed up"
else
    log "   ⚠ No secret key file found"
fi

# Backup 5: Config (if exists)
log "5. Backing up configuration..."
if [ -f "${BACKEND_DIR}/.env" ]; then
    cp "${BACKEND_DIR}/.env" "${BACKUP_PATH}/.env.backup"
    log "   ✓ Configuration backed up"
fi

# Backup 6: Chat history
log "6. Backing up chat history..."
if [ -d "${DATA_DIR}/chat_history" ]; then
    mkdir -p "${BACKUP_PATH}/chat_history"
    cp -r "${DATA_DIR}/chat_history" "${BACKUP_PATH}/chat_history"
    log "   ✓ Chat history backed up"
else
    log "   ⚠ No chat history found"
fi

# Create metadata
log "7. Creating backup metadata..."
cat > "${BACKUP_PATH}/metadata.json" << EOF
{
    "backup_date": "$(date +%Y-%m-%d_%H:%M:%S)",
    "app_version": "1.0.0",
    "backup_tool": "open-connect-auto-backup",
    "hostname": "${HOSTNAME:-unknown}",
    "retention_days": ${RETENTION_DAYS},
    "files_included": [
        "database/webui.db",
        "uploads/",
        "knowledge/",
        ".webui_secret_key",
        ".env.backup",
        "chat_history/",
        "metadata.json"
    ]
}
EOF
log "   ✓ Metadata created"

# Create archive
log "8. Creating archive..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
ARCHIVE_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
rm -rf "${BACKUP_NAME}"
log "   ✓ Archive created: ${ARCHIVE_SIZE}"

# Create latest symlink
ln -sfn "${BACKUP_NAME}.tar.gz" "${BACKUP_DIR}/latest.tar.gz"

# Cleanup old backups
log "9. Cleaning up old backups (retention: ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name "open-connect_backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
OLD_BACKUPS=$(find "${BACKUP_DIR}" -name "open-connect_backup_*.tar.gz" -type f | wc -l)
log "   ✓ Cleanup complete. ${OLD_BACKUPS} backups remaining"

# Verify backup integrity
log "10. Verifying backup integrity..."
if tar -tzf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" > /dev/null 2>&1; then
    log "    ✓ Backup verified successfully"
else
    log_error "Backup verification failed!"
    BACKUP_STATUS=1
fi

log ""
log "=============================================="
if [ $BACKUP_STATUS -eq 0 ]; then
    log "Backup completed successfully!"
else
    log "Backup completed with warnings"
fi
log "=============================================="
log "Archive: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
log "Latest:  ${BACKUP_DIR}/latest.tar.gz -> ${BACKUP_NAME}.tar.gz"
log ""

# Output for logging/monitoring
echo "BACKUP_STATUS=${BACKUP_STATUS}"
echo "BACKUP_FILE=${BACKUP_NAME}.tar.gz"
echo "BACKUP_SIZE=${ARCHIVE_SIZE}"

# Exit with status
exit $BACKUP_STATUS
