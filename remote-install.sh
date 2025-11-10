#!/bin/bash

# Obsidian Vault Skill - Remote Installer
# One-command installation from GitHub
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --user
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --project
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --desktop

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_RAW_URL="https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main"
SKILL_NAME="obsidian-vault"
TEMP_DIR=$(mktemp -d)

# Parse arguments
INSTALL_MODE=""
if [ "$1" = "--user" ] || [ "$1" = "-u" ]; then
    INSTALL_MODE="user"
elif [ "$1" = "--project" ] || [ "$1" = "-p" ]; then
    INSTALL_MODE="project"
elif [ "$1" = "--desktop" ] || [ "$1" = "-d" ]; then
    INSTALL_MODE="desktop"
else
    INSTALL_MODE="interactive"
fi

# Banner
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  📝 Obsidian Vault Skill - Remote Installer${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Interactive mode - ask user what to install
if [ "$INSTALL_MODE" = "interactive" ]; then
    echo -e "${BLUE}Select installation target:${NC}"
    echo ""
    echo "  1. Claude Code - User level (~/.claude/skills/)"
    echo "  2. Claude Code - Project level (./.claude/skills/)"
    echo "  3. Claude Desktop/Web - Download zip file"
    echo "  4. Exit"
    echo ""
    read -p "Enter choice (1-4): " -n 1 -r CHOICE
    echo ""
    echo ""

    case $CHOICE in
        1)
            INSTALL_MODE="user"
            ;;
        2)
            INSTALL_MODE="project"
            ;;
        3)
            INSTALL_MODE="desktop"
            ;;
        4)
            echo "Installation cancelled"
            exit 0
            ;;
        *)
            echo -e "${RED}✗${NC} Invalid choice"
            exit 1
            ;;
    esac
fi

# Function to download file from GitHub
download_file() {
    local file_path=$1
    local output_path=$2
    local url="${GITHUB_RAW_URL}/${file_path}"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output_path"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$output_path" "$url"
    else
        echo -e "${RED}✗${NC} Error: Neither curl nor wget is available"
        exit 1
    fi
}

# Function to install to Claude Code (user level)
install_claude_code_user() {
    echo -e "${GREEN}➜${NC} Installing to Claude Code (User Level)..."
    echo ""

    INSTALL_DIR="$HOME/.claude/skills/$SKILL_NAME"

    # Create directory
    mkdir -p "$INSTALL_DIR"

    # Download SKILL.md
    echo -e "${GREEN}  ↓${NC} Downloading SKILL.md..."
    download_file "SKILL.md" "$INSTALL_DIR/SKILL.md"

    # Download README.md (optional)
    echo -e "${GREEN}  ↓${NC} Downloading README.md..."
    download_file "README.md" "$INSTALL_DIR/README.md" 2>/dev/null || true

    # Download docs
    echo -e "${GREEN}  ↓${NC} Downloading documentation..."
    mkdir -p "$INSTALL_DIR/docs"

    for doc in "openapi.yaml" "api-endpoints.md" "destructive-operation-list.md" \
               "ADR-001-skill-architecture.md" "ADR-002-destructive-operation-guardrails.md" \
               "ADR-003-automatic-backup-system.md" "ADR-004-skill-md-design.md"; do
        download_file "docs/$doc" "$INSTALL_DIR/docs/$doc" 2>/dev/null || true
    done

    echo ""
    echo -e "${GREEN}✓${NC} Skill installed successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📍 Installation Location:"
    echo "     $INSTALL_DIR"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Offer to configure API key
    configure_api_key
}

# Function to install to Claude Code (project level)
install_claude_code_project() {
    echo -e "${GREEN}➜${NC} Installing to Claude Code (Project Level)..."
    echo ""

    INSTALL_DIR="./.claude/skills/$SKILL_NAME"

    # Create directory
    mkdir -p "$INSTALL_DIR"

    # Download SKILL.md
    echo -e "${GREEN}  ↓${NC} Downloading SKILL.md..."
    download_file "SKILL.md" "$INSTALL_DIR/SKILL.md"

    # Download README.md (optional)
    echo -e "${GREEN}  ↓${NC} Downloading README.md..."
    download_file "README.md" "$INSTALL_DIR/README.md" 2>/dev/null || true

    # Download docs
    echo -e "${GREEN}  ↓${NC} Downloading documentation..."
    mkdir -p "$INSTALL_DIR/docs"

    for doc in "openapi.yaml" "api-endpoints.md" "destructive-operation-list.md" \
               "ADR-001-skill-architecture.md" "ADR-002-destructive-operation-guardrails.md" \
               "ADR-003-automatic-backup-system.md" "ADR-004-skill-md-design.md"; do
        download_file "docs/$doc" "$INSTALL_DIR/docs/$doc" 2>/dev/null || true
    done

    echo ""
    echo -e "${GREEN}✓${NC} Skill installed successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📍 Installation Location:"
    echo "     $(pwd)/$INSTALL_DIR"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Suggest .env file for project-level
    echo -e "${YELLOW}💡 Tip:${NC} For project-level installation, create a .env file:"
    echo "   echo 'apiKey=your-api-key-here' > .env"
    echo ""

    configure_api_key
}

# Function to download zip for Claude Desktop
install_claude_desktop() {
    echo -e "${GREEN}➜${NC} Downloading package for Claude Desktop/Web..."
    echo ""

    # Note: We can't programmatically upload to Claude Desktop/Web
    # So we download files and create zip locally

    TEMP_SKILL_DIR="$TEMP_DIR/$SKILL_NAME"
    mkdir -p "$TEMP_SKILL_DIR"

    # Download files
    echo -e "${GREEN}  ↓${NC} Downloading SKILL.md..."
    download_file "SKILL.md" "$TEMP_SKILL_DIR/SKILL.md"

    echo -e "${GREEN}  ↓${NC} Downloading README.md..."
    download_file "README.md" "$TEMP_SKILL_DIR/README.md" 2>/dev/null || true

    echo -e "${GREEN}  ↓${NC} Downloading documentation..."
    mkdir -p "$TEMP_SKILL_DIR/docs"

    for doc in "openapi.yaml" "api-endpoints.md" "destructive-operation-list.md" \
               "ADR-001-skill-architecture.md" "ADR-002-destructive-operation-guardrails.md" \
               "ADR-003-automatic-backup-system.md" "ADR-004-skill-md-design.md"; do
        download_file "docs/$doc" "$TEMP_SKILL_DIR/docs/$doc" 2>/dev/null || true
    done

    # Create zip file
    echo -e "${GREEN}  📦${NC} Creating zip file..."
    OUTPUT_ZIP="$HOME/Downloads/obsidian-vault-skill.zip"

    cd "$TEMP_DIR"
    zip -r "$OUTPUT_ZIP" "$SKILL_NAME" > /dev/null 2>&1

    FILE_SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)

    echo ""
    echo -e "${GREEN}✓${NC} Package created successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📦 Package Details:"
    echo "     File: obsidian-vault-skill.zip"
    echo "     Size: $FILE_SIZE"
    echo "     Location: ~/Downloads/"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BLUE}Upload Instructions:${NC}"
    echo ""
    echo "  For Claude Desktop:"
    echo "    1. Open Claude Desktop"
    echo "    2. Settings → Capabilities → Upload skill"
    echo "    3. Select: ~/Downloads/obsidian-vault-skill.zip"
    echo ""
    echo "  For claude.ai (Web):"
    echo "    1. Go to https://claude.ai"
    echo "    2. Settings → Capabilities → Upload skill"
    echo "    3. Select: ~/Downloads/obsidian-vault-skill.zip"
    echo ""
    echo -e "${YELLOW}⚠️  Requirements:${NC}"
    echo "    • Pro, Max, Team, or Enterprise plan"
    echo "    • Code execution must be enabled"
    echo ""
}

# Function to configure API key
configure_api_key() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚙️  API Key Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This skill requires an API key from Obsidian Local REST API."
    echo ""
    echo -e "${BLUE}Configure now? (y/n):${NC} "
    read -n 1 -r CONFIG_NOW
    echo ""
    echo ""

    if [[ ! $CONFIG_NOW =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⚠️  Skipping configuration${NC}"
        echo ""
        echo "You can configure later using one of:"
        echo "  - Environment variable: export OBSIDIAN_SKILL_API_KEY='your-key'"
        echo "  - Config file: ~/.cc_obsidian/config.json"
        echo "  - Project .env file: apiKey=your-key"
        echo ""
        show_next_steps
        return
    fi

    echo -e "${BLUE}Choose configuration method:${NC}"
    echo ""
    echo "  1. Environment variable (Recommended for user-level)"
    echo "  2. User config file (~/.cc_obsidian/config.json)"
    echo "  3. Project .env file (For project-level only)"
    echo "  4. Skip for now"
    echo ""
    read -p "Enter choice (1-4): " -n 1 -r CONFIG_CHOICE
    echo ""
    echo ""

    case $CONFIG_CHOICE in
        1)
            configure_env_var
            ;;
        2)
            configure_user_config
            ;;
        3)
            configure_project_env
            ;;
        4)
            echo -e "${YELLOW}⚠️  Configuration skipped${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Invalid choice - skipping configuration${NC}"
            ;;
    esac

    echo ""
    show_next_steps
}

# Function to configure environment variable
configure_env_var() {
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
        echo -e "${YELLOW}⚠️  Run this to apply immediately:${NC}"
        echo "   source $SHELL_CONFIG"
    else
        echo -e "${YELLOW}⚠️  Could not detect shell config file${NC}"
        echo "   Add manually:"
        echo "   export OBSIDIAN_SKILL_API_KEY=\"$API_KEY\""
        echo "   export OBSIDIAN_SKILL_API_URL=\"http://localhost:27123\""
    fi
}

# Function to configure user config file
configure_user_config() {
    echo -e "${GREEN}➜${NC} Setting up user config file..."
    echo ""
    read -p "Enter your Obsidian API key: " API_KEY

    CONFIG_DIR="$HOME/.cc_obsidian"
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
}

# Function to configure project .env file
configure_project_env() {
    echo -e "${GREEN}➜${NC} Setting up project .env file..."
    echo ""
    read -p "Enter your Obsidian API key: " API_KEY

    cat > ".env" << EOF
# Obsidian Vault Skill Configuration
apiKey=$API_KEY
apiUrl=http://localhost:27123
allowDelete=false
EOF

    echo -e "${GREEN}✓${NC} .env file created in current directory"
    echo ""
    echo -e "${YELLOW}⚠️  Important:${NC} Add .env to .gitignore to prevent committing secrets!"

    if [ ! -f ".gitignore" ] || ! grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo ".env" >> .gitignore
        echo -e "${GREEN}✓${NC} Added .env to .gitignore"
    fi
}

# Function to show next steps
show_next_steps() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎯 Next Steps:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
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

# Main execution
trap "rm -rf $TEMP_DIR" EXIT

case $INSTALL_MODE in
    user)
        install_claude_code_user
        ;;
    project)
        install_claude_code_project
        ;;
    desktop)
        install_claude_desktop
        ;;
    *)
        echo -e "${RED}✗${NC} Unknown installation mode"
        exit 1
        ;;
esac
