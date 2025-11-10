#!/bin/bash

# Obsidian Vault Skill - Installation Script
# Installs the Obsidian Vault skill to ~/.claude/skills/

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILL_NAME="obsidian-vault"
INSTALL_DIR="$HOME/.claude/skills/$SKILL_NAME"
CONFIG_DIR="$HOME/.cc_obsidian"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📝 Obsidian Vault Skill Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if ~/.claude/skills directory exists
if [ ! -d "$HOME/.claude/skills" ]; then
    echo -e "${YELLOW}⚠️  Creating ~/.claude/skills directory...${NC}"
    mkdir -p "$HOME/.claude/skills"
    echo -e "${GREEN}✓${NC} Directory created"
    echo ""
fi

# Check if skill is already installed
if [ -d "$INSTALL_DIR" ] || [ -L "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  Obsidian Vault skill is already installed at:${NC}"
    echo "   $INSTALL_DIR"
    echo ""
    read -p "   Overwrite? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}✗${NC} Installation cancelled"
        exit 1
    fi
    echo ""
    echo -e "${YELLOW}⚠️  Removing existing installation...${NC}"
    rm -rf "$INSTALL_DIR"
fi

# Create the installation directory
echo -e "${GREEN}➜${NC} Installing Obsidian Vault skill..."
mkdir -p "$INSTALL_DIR"

# Copy necessary files
cp "$SCRIPT_DIR/SKILL.md" "$INSTALL_DIR/"
if [ -f "$SCRIPT_DIR/README.md" ]; then
    cp "$SCRIPT_DIR/README.md" "$INSTALL_DIR/"
fi

# Copy documentation (optional)
if [ -d "$SCRIPT_DIR/docs" ]; then
    mkdir -p "$INSTALL_DIR/docs"
    cp -r "$SCRIPT_DIR/docs/"* "$INSTALL_DIR/docs/" 2>/dev/null || true
fi

echo -e "${GREEN}✓${NC} Skill installed successfully!"
echo ""

# Show what was installed
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📍 Installation Location:"
echo "     $INSTALL_DIR"
echo ""
echo "  📄 Installed Files:"
ls -1 "$INSTALL_DIR" | sed 's/^/     - /'
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if skill file exists
if [ -f "$INSTALL_DIR/SKILL.md" ]; then
    echo -e "${GREEN}✓${NC} SKILL.md found - installation looks good!"
else
    echo -e "${RED}✗${NC} Warning: SKILL.md not found - installation may be incomplete"
fi

echo ""

# Configuration setup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚙️  Configuration Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This skill requires an API key from the Obsidian Local REST API plugin."
echo ""
echo -e "${BLUE}Choose a configuration method:${NC}"
echo ""
echo "  1. Environment variable (Recommended)"
echo "  2. User config file (~/.cc_obsidian/config.json)"
echo "  3. Skip for now (configure manually later)"
echo ""
read -p "Enter choice (1-3): " -n 1 -r CONFIG_CHOICE
echo ""
echo ""

case $CONFIG_CHOICE in
    1)
        echo -e "${GREEN}➜${NC} Setting up environment variable..."
        echo ""
        read -p "Enter your Obsidian API key: " API_KEY

        # Detect shell
        SHELL_CONFIG=""
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            if [ -f "$HOME/.bash_profile" ]; then
                SHELL_CONFIG="$HOME/.bash_profile"
            else
                SHELL_CONFIG="$HOME/.bashrc"
            fi
        fi

        if [ -n "$SHELL_CONFIG" ]; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Obsidian Vault Skill Configuration" >> "$SHELL_CONFIG"
            echo "export OBSIDIAN_SKILL_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"
            echo "export OBSIDIAN_SKILL_API_URL=\"http://localhost:27123\"" >> "$SHELL_CONFIG"
            echo ""
            echo -e "${GREEN}✓${NC} Configuration added to $SHELL_CONFIG"
            echo ""
            echo -e "${YELLOW}⚠️  Run this command to apply immediately:${NC}"
            echo "   source $SHELL_CONFIG"
        else
            echo -e "${YELLOW}⚠️  Could not detect shell config file${NC}"
            echo "   Add these lines to your shell config manually:"
            echo ""
            echo "   export OBSIDIAN_SKILL_API_KEY=\"$API_KEY\""
            echo "   export OBSIDIAN_SKILL_API_URL=\"http://localhost:27123\""
        fi
        ;;
    2)
        echo -e "${GREEN}➜${NC} Setting up user config file..."
        echo ""
        read -p "Enter your Obsidian API key: " API_KEY

        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_DIR/config.json" << EOF
{
  "apiKey": "$API_KEY",
  "apiUrl": "http://localhost:27123",
  "allowDelete": false,
  "backupEnabled": true,
  "backupDirectory": "~/.cc_obsidian/backups",
  "backupKeepLastN": 5,
  "DANGEROUSLY_SKIP_CONFIRMATIONS": false
}
EOF
        echo -e "${GREEN}✓${NC} Config file created at: $CONFIG_DIR/config.json"
        ;;
    3)
        echo -e "${YELLOW}⚠️  Skipping configuration setup${NC}"
        echo ""
        echo "You'll need to configure the API key manually using one of:"
        echo "  - Environment variable: OBSIDIAN_SKILL_API_KEY"
        echo "  - Config file: ~/.cc_obsidian/config.json"
        echo "  - Project .env file"
        echo ""
        echo "See README.md for details."
        ;;
    *)
        echo -e "${YELLOW}⚠️  Invalid choice - skipping configuration${NC}"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Install & Enable Obsidian Local REST API plugin:"
echo "     • Open Obsidian"
echo "     • Settings → Community Plugins → Browse"
echo "     • Search \"Local REST API\" → Install → Enable"
echo "     • Settings → Local REST API → Copy API Key"
echo ""
echo "  2. Restart Claude Code (if already running)"
echo ""
echo "  3. Try these commands:"
echo "     • \"Search my Obsidian vault for notes about X\""
echo "     • \"Read my daily note\""
echo "     • \"Create a new note in Projects folder\""
echo "     • \"Append tasks to today's daily note\""
echo ""
echo "  4. Documentation:"
echo "     • README.md - Setup & usage guide"
echo "     • docs/api-endpoints.md - Complete API reference"
echo "     • docs/ADR-*.md - Architecture decisions"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✨ Installation complete! Your vault awaits!${NC}"
echo ""
