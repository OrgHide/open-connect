#!/usr/bin/env bash
# =============================================================================
# Open Connect - Railway bootstrap entrypoint
# =============================================================================
# Railway-specific responsibilities:
# - Restore the latest backup into the persistent data directory when needed
# - Keep backup naming / storage aligned with Supabase backups
# - Hand off to backend/start.sh for the actual application startup
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}"
BACKEND_START="${BACKEND_DIR}/start.sh"
DATA_DIR="${DATA_DIR:-/app/backend/data}"
RESTORE_DIR="${RESTORE_DIR:-/tmp/restore}"
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
SUPABASE_BUCKET="${SUPABASE_BUCKET:-open-connect-backups}"
BACKUP_PREFIX="${BACKUP_PREFIX:-backups}"
ENABLE_BACKUP_RESTORE_ON_STARTUP="${ENABLE_BACKUP_RESTORE_ON_STARTUP:-false}"
FORCE_BACKUP_RESTORE_ON_STARTUP="${FORCE_BACKUP_RESTORE_ON_STARTUP:-false}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

copy_file_if_exists() {
    local source="$1"
    local target="$2"
    if [[ -f "$source" ]]; then
        mkdir -p "$(dirname "$target")"
        cp -a "$source" "$target"
        return 0
    fi
    return 1
}

copy_dir_contents_if_exists() {
    local source="$1"
    local target="$2"
    if [[ -d "$source" ]]; then
        mkdir -p "$target"
        cp -a "$source"/. "$target"/
        return 0
    fi
    return 1
}

restore_from_tree() {
    local tree_root="$1"
    local restored=0

    copy_file_if_exists "${tree_root}/database/webui.db" "${DATA_DIR}/webui.db" && restored=1
    copy_file_if_exists "${tree_root}/webui.db" "${DATA_DIR}/webui.db" && restored=1
    copy_file_if_exists "${tree_root}/.webui_secret_key" "${BACKEND_DIR}/.webui_secret_key" && restored=1

    copy_dir_contents_if_exists "${tree_root}/uploads" "${DATA_DIR}/uploads" && restored=1
    copy_dir_contents_if_exists "${tree_root}/knowledge" "${DATA_DIR}/knowledge" && restored=1
    copy_dir_contents_if_exists "${tree_root}/chat_history" "${DATA_DIR}/chat_history" && restored=1
    copy_dir_contents_if_exists "${tree_root}/memories" "${DATA_DIR}/memories" && restored=1
    copy_dir_contents_if_exists "${tree_root}/notes" "${DATA_DIR}/notes" && restored=1

    if [[ -d "${tree_root}/cache/embedding" ]]; then
        mkdir -p "${DATA_DIR}/cache"
        copy_dir_contents_if_exists "${tree_root}/cache/embedding" "${DATA_DIR}/cache/embedding" && restored=1
    fi

    if [[ "$restored" -eq 1 ]]; then
        chmod -R 755 "${DATA_DIR}" 2>/dev/null || true
        chmod 600 "${BACKEND_DIR}/.webui_secret_key" 2>/dev/null || true
        return 0
    fi

    return 1
}

restore_from_archive() {
    local archive_path="$1"
    local temp_dir backup_root

    temp_dir="$(mktemp -d)"
    trap 'rm -rf "${temp_dir}"' RETURN

    tar -xzf "$archive_path" -C "$temp_dir"

    backup_root="$(find "$temp_dir" -maxdepth 2 -type d \
        \( -name 'open-connect_backup_*' -o -name 'open-connect-backup-*' -o -name '*backup*' \) \
        | head -1 || true)"

    if [[ -z "$backup_root" ]]; then
        backup_root="$temp_dir"
    fi

    restore_from_tree "$backup_root"
}

restore_from_local_package() {
    if [[ -f "${RESTORE_DIR}/latest.tar.gz" ]]; then
        log "Restoring from local package: ${RESTORE_DIR}/latest.tar.gz"
        restore_from_archive "${RESTORE_DIR}/latest.tar.gz"
        return 0
    fi

    if [[ -f "${RESTORE_DIR}/restore_package.tar.gz" ]]; then
        log "Restoring from local package: ${RESTORE_DIR}/restore_package.tar.gz"
        restore_from_archive "${RESTORE_DIR}/restore_package.tar.gz"
        return 0
    fi

    if [[ -f "${RESTORE_DIR}/webui.db" || -f "${RESTORE_DIR}/latest.sqlite" ]]; then
        log "Restoring from local sqlite snapshot"
        copy_file_if_exists "${RESTORE_DIR}/webui.db" "${DATA_DIR}/webui.db" || true
        copy_file_if_exists "${RESTORE_DIR}/latest.sqlite" "${DATA_DIR}/webui.db" || true
        copy_file_if_exists "${RESTORE_DIR}/.webui_secret_key" "${BACKEND_DIR}/.webui_secret_key" || true
        chmod -R 755 "${DATA_DIR}" 2>/dev/null || true
        chmod 600 "${BACKEND_DIR}/.webui_secret_key" 2>/dev/null || true
        return 0
    fi

    return 1
}

restore_from_supabase() {
    if [[ -z "$SUPABASE_PROJECT_REF" ]] || [[ -z "$SUPABASE_ACCESS_TOKEN" ]]; then
        warn "Supabase restore skipped: missing SUPABASE_PROJECT_REF or SUPABASE_ACCESS_TOKEN"
        return 1
    fi

    local list_response latest_backup download_url archive_path
    archive_path="${RESTORE_DIR}/latest.tar.gz"
    mkdir -p "$RESTORE_DIR"

    list_response="$(curl -fsSL --max-time 30 \
        "https://api.supabase.com/v1/storage/${SUPABASE_BUCKET}/objects/list" \
        -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"prefix\": \"${BACKUP_PREFIX}/\"}" )" || {
        warn "Failed to list backups from Supabase"
        return 1
    }

    latest_backup="$(printf '%s' "$list_response" | jq -r 'sort_by(.created_at) | last.name // empty')"
    if [[ -z "$latest_backup" ]]; then
        warn "No Supabase backups found under prefix ${BACKUP_PREFIX}/"
        return 1
    fi

    download_url="https://api.supabase.com/v1/storage/${SUPABASE_BUCKET}/objects/download/${latest_backup}"
    log "Downloading latest Supabase backup: ${latest_backup}"
    curl -fsSL --max-time 120 \
        "$download_url" \
        -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
        -o "$archive_path"

    restore_from_archive "$archive_path"
}

should_restore="false"
if [[ "${ENABLE_BACKUP_RESTORE_ON_STARTUP,,}" == "true" ]]; then
    if [[ "${FORCE_BACKUP_RESTORE_ON_STARTUP,,}" == "true" ]] || [[ ! -s "${DATA_DIR}/webui.db" ]]; then
        should_restore="true"
    fi
fi

if [[ "$should_restore" == "true" ]]; then
    log "Backup restore enabled; checking local and remote sources"
    if restore_from_local_package; then
        log "Local restore package applied"
    elif restore_from_supabase; then
        log "Remote Supabase backup restored"
    else
        warn "No backup restored; continuing with existing data or a fresh database"
    fi
else
    log "Backup restore skipped (data already present or restore disabled)"
fi

if [[ ! -f "$BACKEND_START" ]]; then
    error "Backend startup script not found at ${BACKEND_START}"
    exit 1
fi

exec bash "$BACKEND_START" "$@"
