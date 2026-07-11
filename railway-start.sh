#!/usr/bin/env bash
# Compatibility wrapper for Railway deployments.
#
# The authoritative production startup flow now lives in backend/start.sh,
# which already handles PORT binding, secret key creation, health checks,
# and the app boot sequence without the extra blocking startup gate that
# caused Railway to mark deployments unhealthy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_START="${SCRIPT_DIR}/start.sh"

if [[ ! -f "$BACKEND_START" ]]; then
    echo "backend/start.sh not found at: $BACKEND_START" >&2
    exit 1
fi

exec bash "$BACKEND_START" "$@"
