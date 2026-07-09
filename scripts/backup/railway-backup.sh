#!/bin/bash
# Open Connect Railway Backup Script
# This script backs up data from Railway persistent volumes
# Can be run manually or scheduled via Railway's cron feature

set -euo pipefail

# Configuration
BACKUP_DEST="${BACKUP_DEST:-/tmp/backups}"
KEEP_BACKUPS="${KEEP_BACKUPS:-5}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="open-connect-${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DEST}/${BACKUP_NAME}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check for Railway volume
RAILWAY_VOLUME_MOUNT_DIR="/app/backend/data"

log "=============================================="
log "Open Connect Railway Backup"
log "=============================================="
log "Source: ${RAILWAY_VOLUME_MOUNT_DIR}"
log "Destination: ${BACKUP_PATH}"
log ""

# Create backup directory
mkdir -p "${BACKUP_PATH}"
mkdir -p "${BACKUP_DEST}"

# Backup database
log "Backing up database..."
if [ -f "${RAILWAY_VOLUME_MOUNT_DIR}/webui.db" ]; then
    cp "${RAILWAY_VOLUME_MOUNT_DIR}/webui.db" "${BACKUP_PATH}/webui.db"
    log "✓ Database backed up"
else
    log "⚠ No database found"
fi

# Backup uploads
log "Backing up uploads..."
if [ -d "${RAILWAY_VOLUME_MOUNT_DIR}/uploads" ]; then
    cp -r "${RAILWAY_VOLUME_MOUNT_DIR}/uploads" "${BACKUP_PATH}/"
    log "✓ Uploads backed up"
fi

# Backup knowledge
log "Backing up knowledge base..."
if [ -d "${RAILWAY_VOLUME_MOUNT_DIR}/knowledge" ]; then
    cp -r "${RAILWAY_VOLUME_MOUNT_DIR}/knowledge" "${BACKUP_PATH}/"
    log "✓ Knowledge base backed up"
fi

# Backup secret key
log "Backing up secret key..."
if [ -f "/app/backend/.webui_secret_key" ]; then
    cp "/app/backend/.webui_secret_key" "${BACKUP_PATH}/"
    log "✓ Secret key backed up"
fi

# Create archive
log "Creating archive..."
cd "${BACKUP_DEST}"
tar -czf "${BACKUP_NAME}.tar.gz" -C "${BACKUP_DEST}" "${BACKUP_NAME}"
rm -rf "${BACKUP_PATH}"

# Update latest symlink
ln -sfn "${BACKUP_NAME}.tar.gz" "${BACKUP_DEST}/latest.tar.gz"

log "✓ Backup created: ${BACKUP_NAME}.tar.gz"

# Cleanup old backups
log "Cleaning up old backups (keeping ${KEEP_BACKUPS})..."
cd "${BACKUP_DEST}"
ls -t open-connect-*.tar.gz 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm -f

log ""
log "=============================================="
log "Backup completed!"
log "=============================================="
log "Files available:"
ls -lh "${BACKUP_DEST}"/open-connect-*.tar.gz 2>/dev/null | tail -5
