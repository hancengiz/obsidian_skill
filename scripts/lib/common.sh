#!/bin/bash

# Common utilities and definitions for Obsidian Vault Skill installers

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
print_banner() {
    local title="$1"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $title${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Print section header
print_section() {
    local title="$1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Detect shell config file
detect_shell_config() {
    local shell_config=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bash_profile" ]; then
            shell_config="$HOME/.bash_profile"
        else
            shell_config="$HOME/.bashrc"
        fi
    fi
    echo "$shell_config"
}

# Show next steps
show_next_steps() {
    print_section "🎯 Next Steps:"
    echo "  1. Install Obsidian Local REST API plugin:"
    echo "     • Obsidian → Settings → Community Plugins"
    echo "     • Search \"Local REST API\" → Install & Enable"
    echo "     • Copy your API key from plugin settings"
    echo ""
    echo "  2. Restart Claude Code (if already running)"
    echo ""
    echo "  3. Try these commands:"
    echo "     • \"Search my Obsidian vault for notes about X\""
    echo "     • \"Read my daily note\""
    echo "     • \"Create a new note in Projects folder\""
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}✨ Installation complete!${NC}"
    echo ""
}
