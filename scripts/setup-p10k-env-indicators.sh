#!/bin/bash
# Setup script to add environment indicators to Powerlevel10k prompt
# This script modifies ~/.p10k.zsh to include env_indicators segment

set -e

echo "🔧 Setting up Powerlevel10k environment indicators..."
echo ""

# Check if .p10k.zsh exists
if [[ ! -f "$HOME/.p10k.zsh" ]]; then
    echo "❌ Error: ~/.p10k.zsh not found"
    echo "Please run 'p10k configure' first to generate the configuration file"
    exit 1
fi

# Backup the file
cp "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.backup"
echo "✅ Backed up ~/.p10k.zsh to ~/.p10k.zsh.backup"

# Check if env_indicators is already added
if grep -q "env_indicators" "$HOME/.p10k.zsh"; then
    echo "ℹ️  env_indicators segment already configured"
    exit 0
fi

# Find the RIGHT_PROMPT_ELEMENTS line and add env_indicators
# The segment should be near the beginning of RIGHT_PROMPT_ELEMENTS
sed -i.bak2 '/typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(/,/)/s/(/(&\n    env_indicators/' "$HOME/.p10k.zsh"

# Also add the prompt_env_indicators function definition if not present
if ! grep -q "prompt_env_indicators()" "$HOME/.p10k.zsh"; then
    # Add the function at the end of the file, before the last line
    cat >> "$HOME/.p10k.zsh" << 'EOF'

# Environment indicators segment (custom)
prompt_env_indicators() {
    # This function is called by Powerlevel10k to display env indicators
    # It sources the function from ~/.zsh/functions/context.zsh
    if typeset -f _get_env_indicators &>/dev/null; then
        local indicators=$(_get_env_indicators)
        [[ -n "$indicators" ]] && print -P "$indicators"
    fi
}
EOF
    echo "✅ Added prompt_env_indicators function to ~/.p10k.zsh"
fi

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: exec zsh"
echo "2. Reload p10k if needed: p10k reload"
echo ""
echo "The environment indicators should now appear in the top-right corner of your prompt."
