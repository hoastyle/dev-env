# ===============================================
# Environment Variables
# ===============================================
# Description: Global environment variables and PATH configuration

# Google Cloud Project
export GOOGLE_CLOUD_PROJECT="gen-lang-client-0165913056"

# ===============================================
# User-Local Binary PATH (~/.local/bin)
# ===============================================
# Add ~/.local/bin to PATH for user-installed tools (e.g., uv, pipx, etc.)
# This script uses intelligent PATH management to avoid duplicate entries
# Source: uv installer and XDG Base Directory Specification
if [[ -f "$HOME/.local/bin/env" ]]; then
    source "$HOME/.local/bin/env"
fi
