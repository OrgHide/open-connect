#!/bin/bash
# Open Connect Restore Script
# This script restores data from a backup

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATA_DIR="${DATA_DIR:-./backend/data}"
BACKEND_DIR="${BACKEND_DIR:-./backend}"

echo "=============================================="
echo "Open Connect Restore Script"
echo "=============================================="

# Check for backup file argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    echo ""
    echo "Available backups:"
    ls -la "${BACKUP_DIR}"/open-connect_backup_*.tar.gz 2>/dev/null || echo "No backups found in ${BACKUP_DIR}"
    exit 1
fi

BACKUP_FILE="$1"

# Validate backup file
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Create temporary extraction directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

echo "Extracting backup: ${BACKUP_FILE}"
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Find the extracted backup directory
BACKUP_PATH=$(find "${TEMP_DIR}" -maxdepth 1 -type d -name "open-connect_backup_*" | head -1)

if [ -z "${BACKUP_PATH}" ]; then
    echo "Error: Invalid backup format"
    exit 1
fi

echo "Backup extracted to: ${BACKUP_PATH}"
echo ""

# Show backup info
if [ -f "${BACKUP_PATH}/metadata.json" ]; then
    echo "Backup Information:"
    cat "${BACKUP_PATH}/metadata.json"
    echo ""
fi

echo "Starting restore process..."
echo ""

# Restore 1: Database
echo "1. Restoring database..."
if [ -f "${BACKUP_PATH}/database/webui.db" ]; then
    mkdir -p "${DATA_DIR}"
    cp "${BACKUP_PATH}/database/webui.db" "${DATA_DIR}/webui.db"
    echo "   ✓ Database restored to ${DATA_DIR}/webui.db"
else
    echo "   ⚠ No database in backup"
fi

# Restore 2: Uploads
echo "2. Restoring user uploads..."
if [ -d "${BACKUP_PATH}/uploads" ]; then
    mkdir -p "${DATA_DIR}"
    cp -r "${BACKUP_PATH}/uploads" "${DATA_DIR}/uploads"
    echo "   ✓ User uploads restored"
else
    echo "   ⚠ No uploads in backup"
fi

# Restore 3: Cache
echo "3. Restoring cache..."
if [ -d "${BACKUP_PATH}/cache/embedding" ]; then
    mkdir -p "${DATA_DIR}/cache"
    cp -r "${BACKUP_PATH}/cache/embedding" "${DATA_DIR}/cache/embedding"
    echo "   ✓ Embedding models cache restored"
else
    echo "   ⚠ No cache in backup"
fi

# Restore 4: Secret key
echo "4. Restoring secret key..."
if [ -f "${BACKUP_PATH}/.webui_secret_key" ]; then
    cp "${BACKUP_PATH}/.webui_secret_key" "${BACKEND_DIR}/.webui_secret_key"
    echo "   ✓ Secret key restored"
else
    echo "   ⚠ No secret key in backup"
fi

# Restore 5: Environment template
echo "5. Restoring environment template..."
if [ -f "${BACKUP_PATH}/.env.template" ]; then
    if [ ! -f "${BACKEND_DIR}/.env" ]; then
        cp "${BACKUP_PATH}/.env.template" "${BACKEND_DIR}/.env"
        echo "   ✓ Environment template copied to ${BACKEND_DIR}/.env"
        echo "   ⚠ Please edit .env and fill in your API keys"
    else
        echo "   ⚠ .env already exists, skipping"
    fi
else
    echo "   ⚠ No environment template in backup"
fi

echo ""
echo "=============================================="
echo "Restore completed successfully!"
echo "=============================================="
echo ""
echo "IMPORTANT:"
echo "1. Restart the application to apply changes"
echo "2. Verify all API keys are set correctly"
echo "3. Check that the database is accessible"
echo ""
