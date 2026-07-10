#!/usr/bin/env bash
# =============================================================================
# Open Connect - Plugin Installation Script
# =============================================================================
# Installs plugins from:
# - Fu-Jie/openwebui-extensions
# - iChristGit/OpenWebui-Tools
# - Haervwe/open-webui-tools
# - Classic298/open-webui-plugins
# - suurt8ll/open_webui_functions
# - rbb-dev/Open-WebUI-OpenRouter-pipe
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local color="${NC}"
    
    case "$level" in
        ERROR)  color="${RED}";    level="ERROR" ;;
        WARN)   color="${YELLOW}";  level="WARN" ;;
        SUCCESS) color="${GREEN}";  level="SUCCESS" ;;
        INFO)    color="${BLUE}";   level="INFO" ;;
    esac
    
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${message}${NC}"
}

log_info()    { log "INFO" "$1"; }
log_success() { log "SUCCESS" "$1"; }
log_warn()    { log "WARN" "$1"; }
log_error()   { log "ERROR" "$1"; }

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="${PLUGINS_DIR:-/app/backend/open_webui/plugins}"
BACKEND_DIR="${BACKEND_DIR:-/app/backend}"

# Plugin repositories to install
declare -A PLUGIN_REPOS=(
    ["Fu-Jie/openwebui-extensions"]="https://github.com/Fu-Jie/openwebui-extensions.git"
    ["iChristGit/OpenWebui-Tools"]="https://github.com/iChristGit/OpenWebui-Tools.git"
    ["Haervwe/open-webui-tools"]="https://github.com/Haervwe/open-webui-tools.git"
    ["Classic298/open-webui-plugins"]="https://github.com/Classic298/open-webui-plugins.git"
    ["suurt8ll/open_webui_functions"]="https://github.com/suurt8ll/open_webui_functions.git"
    ["rbb-dev/Open-WebUI-OpenRouter-pipe"]="https://github.com/rbb-dev/Open-WebUI-OpenRouter-pipe.git"
)

# =============================================================================
# Functions
# =============================================================================

install_git_plugin() {
    local repo="$1"
    local url="$2"
    local temp_dir="/tmp/plugin_install_$(date +%s)"
    
    log_info "Installing plugin from ${repo}..."
    
    # Clone to temp directory
    if git clone --depth 1 "$url" "$temp_dir" 2>/dev/null; then
        # Check for main plugin files
        local plugin_found=false
        
        # Look for various plugin file patterns
        for pattern in "*.py" "openwebui_tools.py" "tools.py" "functions.py" "main.py" "plugin.py"; do
            while IFS= read -r file; do
                if [[ -f "$file" ]]; then
                    local filename=$(basename "$file")
                    local dest_file="${PLUGINS_DIR}/${filename}"
                    
                    # Avoid overwriting if file exists
                    if [[ ! -f "$dest_file" ]]; then
                        cp "$file" "$dest_file"
                        log_success "  Installed: $filename"
                        plugin_found=true
                    else
                        log_info "  Skipped (exists): $filename"
                    fi
                fi
            done < <(find "$temp_dir" -maxdepth 3 -name "$pattern" -type f 2>/dev/null)
        done
        
        # Check for pip requirements
        if [[ -f "${temp_dir}/requirements.txt" ]]; then
            log_info "  Installing Python dependencies..."
            pip install -r "${temp_dir}/requirements.txt" --quiet 2>/dev/null || true
        fi
        
        # Check for package structure
        if [[ -d "${temp_dir}/src" ]]; then
            cp -r "${temp_dir}/src"/* "${PLUGINS_DIR}/" 2>/dev/null || true
            log_success "  Installed from src/"
        fi
        
        if [[ -d "${temp_dir}/openwebui" ]]; then
            cp -r "${temp_dir}/openwebui"/* "${PLUGINS_DIR}/" 2>/dev/null || true
            log_success "  Installed from openwebui/"
        fi
        
        # Check for skills directory
        if [[ -d "${temp_dir}/skills" ]]; then
            local skills_dir="${BACKEND_DIR}/open_webui/skills"
            mkdir -p "$skills_dir"
            cp -r "${temp_dir}/skills"/* "$skills_dir/" 2>/dev/null || true
            log_success "  Installed skills"
        fi
        
        # Check for pipelines (Open WebUI functions/pipelines)
        if [[ -d "${temp_dir}/pipelines" ]]; then
            local pipelines_dir="${BACKEND_DIR}/open_webui/pipelines"
            mkdir -p "$pipelines_dir"
            cp -r "${temp_dir}/pipelines"/* "$pipelines_dir/" 2>/dev/null || true
            log_success "  Installed pipelines"
        fi
        
        # Check for connectors
        if [[ -d "${temp_dir}/connectors" ]]; then
            local connectors_dir="${BACKEND_DIR}/open_webui/connectors"
            mkdir -p "$connectors_dir"
            cp -r "${temp_dir}/connectors"/* "$connectors_dir/" 2>/dev/null || true
            log_success "  Installed connectors"
        fi
        
        # Check for models
        if [[ -d "${temp_dir}/models" ]]; then
            local models_dir="${BACKEND_DIR}/open_webui/models"
            mkdir -p "$models_dir"
            cp -r "${temp_dir}/models"/* "$models_dir/" 2>/dev/null || true
            log_success "  Installed models"
        fi
        
        if $plugin_found; then
            log_success "Plugin ${repo} installed successfully"
        else
            log_warn "No plugin files found in ${repo}"
        fi
        
        # Cleanup
        rm -rf "$temp_dir"
    else
        log_error "Failed to clone ${repo}"
    fi
}

install_github_release() {
    local repo="$1"
    local url="$2"
    
    log_info "Checking for release assets in ${repo}..."
    
    # Extract owner/repo
    local owner=$(echo "$repo" | cut -d'/' -f1)
    local name=$(echo "$repo" | cut -d'/' -f2)
    
    # Get latest release info
    local api_url="https://api.github.com/repos/${owner}/${name}/releases/latest"
    
    if command -v curl &>/dev/null; then
        local response=$(curl -sf "$api_url" 2>/dev/null || echo "{}")
        local download_url=$(echo "$response" | grep -o '"browser_download_url": "[^"]*' | head -1 | cut -d'"' -f4)
        
        if [[ -n "$download_url" ]]; then
            log_info "  Found release asset: $download_url"
            local filename=$(basename "$download_url")
            local temp_file="/tmp/${filename}"
            
            curl -sfL "$download_url" -o "$temp_file" 2>/dev/null
            
            if [[ -f "$temp_file" ]]; then
                # Extract to plugins directory
                mkdir -p "${PLUGINS_DIR}"
                
                if [[ "$filename" == *.zip ]]; then
                    unzip -o "$temp_file" -d "${PLUGINS_DIR}" 2>/dev/null || true
                elif [[ "$filename" == *.tar.gz ]]; then
                    tar -xzf "$temp_file" -C "${PLUGINS_DIR}" 2>/dev/null || true
                fi
                
                rm -f "$temp_file"
                log_success "Installed release from ${repo}"
            fi
        fi
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    log_info "=========================================="
    log_info "Open Connect - Plugin Installation"
    log_info "=========================================="
    
    # Check for git
    if ! command -v git &>/dev/null; then
        log_error "Git is required but not installed"
        exit 1
    fi
    
    # Create plugins directory
    mkdir -p "${PLUGINS_DIR}"
    log_info "Plugins directory: ${PLUGINS_DIR}"
    
    # Install each plugin repository
    for repo in "${!PLUGIN_REPOS[@]}"; do
        local url="${PLUGIN_REPOS[$repo]}"
        install_git_plugin "$repo" "$url" || true
        echo ""
    done
    
    # Verify installation
    log_info "=========================================="
    log_info "Installation Summary"
    log_info "=========================================="
    
    local plugin_count=$(find "${PLUGINS_DIR}" -maxdepth 1 -name "*.py" -type f 2>/dev/null | wc -l)
    log_info "Plugins installed: ${plugin_count}"
    
    if [[ -d "${BACKEND_DIR}/open_webui/skills" ]]; then
        local skills_count=$(find "${BACKEND_DIR}/open_webui/skills" -name "*.md" -type f 2>/dev/null | wc -l)
        log_info "Skills installed: ${skills_count}"
    fi
    
    if [[ -d "${BACKEND_DIR}/open_webui/pipelines" ]]; then
        local pipelines_count=$(find "${BACKEND_DIR}/open_webui/pipelines" -name "*.py" -type f 2>/dev/null | wc -l)
        log_info "Pipelines installed: ${pipelines_count}"
    fi
    
    log_success "Plugin installation complete!"
    echo ""
}

main "$@"
