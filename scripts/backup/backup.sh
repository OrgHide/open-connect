#!/bin/bash
# Open Connect Backup Script
# This script backs up all essential data for migration

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="open-connect_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Directories to backup
DATA_DIR="${DATA_DIR:-./backend/data}"
BACKEND_DIR="${BACKEND_DIR:-./backend}"

# Create backup directory
mkdir -p "${BACKUP_PATH}"

echo "=============================================="
echo "Open Connect Backup Script"
echo "=============================================="
echo "Backup Location: ${BACKUP_PATH}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Backup 1: Database
echo "1. Backing up database..."
if [ -f "${DATA_DIR}/webui.db" ]; then
    mkdir -p "${BACKUP_PATH}/database"
    cp "${DATA_DIR}/webui.db" "${BACKUP_PATH}/database/webui.db"
    echo "   ✓ Database backed up: ${DATA_DIR}/webui.db"
else
    echo "   ⚠ No database found at ${DATA_DIR}/webui.db"
fi

# Backup 2: User uploads and files
echo "2. Backing up user data..."
if [ -d "${DATA_DIR}/uploads" ]; then
    mkdir -p "${BACKUP_PATH}/uploads"
    cp -r "${DATA_DIR}/uploads" "${BACKUP_PATH}/uploads"
    echo "   ✓ User uploads backed up"
else
    echo "   ⚠ No uploads directory found"
fi

# Backup 3: Cache
echo "3. Backing up cache..."
if [ -d "${DATA_DIR}/cache" ]; then
    mkdir -p "${BACKUP_PATH}/cache"
    # Only backup embedding models (the rest can be re-downloaded)
    if [ -d "${DATA_DIR}/cache/embedding" ]; then
        cp -r "${DATA_DIR}/cache/embedding" "${BACKUP_PATH}/cache/embedding"
        echo "   ✓ Embedding models cache backed up"
    fi
else
    echo "   ⚠ No cache directory found"
fi

# Backup 4: Secret key
echo "4. Backing up secret key..."
if [ -f "${BACKEND_DIR}/.webui_secret_key" ]; then
    cp "${BACKEND_DIR}/.webui_secret_key" "${BACKUP_PATH}/.webui_secret_key"
    echo "   ✓ Secret key backed up"
else
    echo "   ⚠ No secret key file found"
fi

# Backup 5: Environment configuration template
echo "5. Creating environment template..."
cat > "${BACKUP_PATH}/.env.template" << 'EOF'
# Open Connect Environment Variables Template
# Copy this file to .env and fill in your values

# App Settings
APP_NAME=Open Connect
ENV=prod
WEBUI_NAME=Open Connect

# Security
WEBUI_SECRET_KEY=  # Generate with: head -c 24 /dev/random | base64

# Database (leave empty for SQLite)
# DATABASE_URL=postgresql://user:password@host:port/dbname

# AI Provider API Keys
# OpenRouter (recommended for free tier)
OPENAI_API_KEY=your_openrouter_api_key
OPENAI_API_BASE_URL=https://openrouter.ai/api/v1

# Hugging Face
HUGGINGFACE_TOKEN=your_huggingface_token

# Groq
GROQ_API_KEY=your_groq_api_key

# Docker mode (required for Railway)
DOCKER=true

# Port
PORT=8080
EOF
echo "   ✓ Environment template created"

# Backup 6: Metadata
echo "6. Creating backup metadata..."
cat > "${BACKUP_PATH}/metadata.json" << EOF
{
    "backup_date": "${TIMESTAMP}",
    "app_version": "1.0.0",
    "backup_tool": "open-connect-backup",
    "files_included": [
        "database/webui.db",
        "uploads/",
        "cache/embedding/",
        ".webui_secret_key",
        ".env.template",
        "metadata.json"
    ]
}
EOF
echo "   ✓ Metadata created"

# Create archive
echo ""
echo "7. Creating archive..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"
echo "   ✓ Archive created: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# Cleanup old backups (keep last 7)
echo ""
echo "8. Cleaning up old backups..."
ls -t "${BACKUP_DIR}"/open-connect_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
echo "   ✓ Cleanup complete"

echo ""
echo "=============================================="
echo "Backup completed successfully!"
echo "=============================================="
echo "Backup file: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo ""
echo "To restore:"
echo "  tar -xzf ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz -C ${BACKUP_DIR}/"
echo "  # Copy files back to their original locations"
echo ""
