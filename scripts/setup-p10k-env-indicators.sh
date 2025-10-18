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
# Use a safer approach: insert after the opening line with proper formatting
sed -i.bak2 '/typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(/a\    env_indicators' "$HOME/.p10k.zsh"

# Also add the prompt_env_indicators function definition if not present
if ! grep -q "function prompt_env_indicators()" "$HOME/.p10k.zsh"; then
    # Find the line number where we should insert the function
    # Insert after the closing brace of the main config function
    line_num=$(grep -n "^}" "$HOME/.p10k.zsh" | tail -1 | cut -d: -f1)

    # Create temporary file with the function
    cat > /tmp/p10k_env_function.txt << 'FUNC_EOF'

# ===============================================
# Environment Indicators Custom Segment
# ===============================================
# Displays container status, SSH status, and proxy status
# on the right side of the first line of the prompt

function prompt_env_indicators() {
  # Load environment detection functions from ~/.zsh/functions/context.zsh
  if typeset -f _get_env_indicators &>/dev/null; then
    local indicators=$(_get_env_indicators)
    # Use p10k segment to display icons (no background, no foreground colors)
    [[ -n "$indicators" ]] && p10k segment -t "$indicators"
  fi
}

# Instant prompt support (ensures indicators appear in instant prompt)
function instant_prompt_env_indicators() {
  prompt_env_indicators
}
FUNC_EOF

    # Insert the function at the correct location
    sed -i "${line_num} r /tmp/p10k_env_function.txt" "$HOME/.p10k.zsh"
    rm /tmp/p10k_env_function.txt

    echo "✅ Added prompt_env_indicators function to ~/.p10k.zsh"
fi

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: exec zsh"
echo "2. Reload p10k if needed: p10k reload"
echo ""
echo "The environment indicators should now appear in the top-right corner of your prompt."
