#!/bin/bash

# Core installation logic for Obsidian Vault Skill
# This file is sourced by both local-install.sh and remote-install.sh

# Requires common.sh to be sourced first
# Requires MODE variable to be set: "local" or "remote"

SKILL_NAME="obsidian-vault"
CONFIG_DIR="$HOME/.cc_obsidian"

# Download file from GitHub (for remote mode)
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

# Copy or download a file depending on mode
copy_or_download() {
    local file=$1
    local dest=$2

    if [ "$MODE" = "local" ]; then
        if [ -f "$SOURCE_DIR/$file" ]; then
            cp "$SOURCE_DIR/$file" "$dest"
            return 0
        else
            echo -e "${YELLOW}⚠️  Warning: $file not found${NC}"
            return 1
        fi
    else
        download_file "$file" "$dest" 2>/dev/null || return 1
    fi
}

# Install to user-level Claude Code
install_to_user_level() {
    echo -e "${GREEN}➜${NC} Installing to Claude Code (User Level)..."
    echo ""

    local install_dir="$HOME/.claude/skills/$SKILL_NAME"

    # Check if already installed
    if [ -d "$install_dir" ] || [ -L "$install_dir" ]; then
        echo -e "${YELLOW}⚠️  Obsidian Vault skill is already installed at:${NC}"
        echo "   $install_dir"
        echo ""
        read -p "   Overwrite? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}✗${NC} Installation cancelled"
            exit 1
        fi
        echo ""
        echo -e "${YELLOW}⚠️  Removing existing installation...${NC}"
        rm -rf "$install_dir"
    fi

    # Create directory
    mkdir -p "$install_dir"

    # Copy/download only SKILL.md and README.md
    echo -e "${GREEN}  ↓${NC} Installing SKILL.md..."
    copy_or_download "SKILL.md" "$install_dir/SKILL.md"

    echo -e "${GREEN}  ↓${NC} Installing README.md..."
    copy_or_download "README.md" "$install_dir/README.md"

    echo ""
    echo -e "${GREEN}✓${NC} Skill installed successfully!"
    echo ""
    print_section "📍 Installation Location:"
    echo "     $install_dir"
    echo ""
    echo "  📄 Installed Files:"
    echo "     - SKILL.md"
    echo "     - README.md"
    echo ""
    echo "  📚 Documentation:"
    echo "     View full docs at: https://github.com/hancengiz/obsidian-vault-skill/tree/main/docs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Install commands to user level
    install_commands_user_level
}

# Install to project-level Claude Code
install_to_project_level() {
    echo -e "${GREEN}➜${NC} Installing to Claude Code (Project Level)..."
    echo ""

    local install_dir="./.claude/skills/$SKILL_NAME"

    # Create directory
    mkdir -p "$install_dir"

    # Copy/download only SKILL.md and README.md
    echo -e "${GREEN}  ↓${NC} Installing SKILL.md..."
    copy_or_download "SKILL.md" "$install_dir/SKILL.md"

    echo -e "${GREEN}  ↓${NC} Installing README.md..."
    copy_or_download "README.md" "$install_dir/README.md"

    echo ""
    echo -e "${GREEN}✓${NC} Skill installed successfully!"
    echo ""
    print_section "📍 Installation Location:"
    echo "     $(pwd)/$install_dir"
    echo ""
    echo "  📄 Installed Files:"
    echo "     - SKILL.md"
    echo "     - README.md"
    echo ""
    echo "  📚 Documentation:"
    echo "     View full docs at: https://github.com/hancengiz/obsidian-vault-skill/tree/main/docs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Install commands to project level
    install_commands_project_level

    echo -e "${YELLOW}💡 Tip:${NC} For project-level installation, create a .env file:"
    echo "   echo 'apiKey=your-api-key-here' > .env"
    echo ""
}

# Configure environment variable
configure_env_var() {
    echo -e "${GREEN}➜${NC} Setting up environment variable..."
    echo ""
    read -p "Enter your Obsidian API key: " API_KEY

    local shell_config=$(detect_shell_config)

    if [ -n "$shell_config" ]; then
        echo "" >> "$shell_config"
        echo "# Obsidian Vault Skill Configuration" >> "$shell_config"
        echo "export OBSIDIAN_SKILL_API_KEY=\"$API_KEY\"" >> "$shell_config"
        echo "export OBSIDIAN_SKILL_API_URL=\"https://localhost:27124\"" >> "$shell_config"
        echo ""
        echo -e "${GREEN}✓${NC} Configuration added to $shell_config"
        echo ""
        echo -e "${YELLOW}⚠️  Run this to apply immediately:${NC}"
        echo "   source $shell_config"
    else
        echo -e "${YELLOW}⚠️  Could not detect shell config file${NC}"
        echo "   Add manually:"
        echo "   export OBSIDIAN_SKILL_API_KEY=\"$API_KEY\""
        echo "   export OBSIDIAN_SKILL_API_URL=\"https://localhost:27124\""
    fi
}

# Configure user config file
configure_user_config() {
    echo -e "${GREEN}➜${NC} Setting up user config file..."
    echo ""
    read -p "Enter your Obsidian API key: " API_KEY

    mkdir -p "$CONFIG_DIR"

    cat > "$CONFIG_DIR/config.json" << EOF
{
  "apiKey": "$API_KEY",
  "apiUrl": "https://localhost:27124",
  "allowDelete": false,
  "backupEnabled": true,
  "backupDirectory": "~/.cc_obsidian/backups",
  "backupKeepLastN": 5,
  "DANGEROUSLY_SKIP_CONFIRMATIONS": false
}
EOF

    echo -e "${GREEN}✓${NC} Config file created at: $CONFIG_DIR/config.json"
}

# Configure project .env file
configure_project_env() {
    echo -e "${GREEN}➜${NC} Setting up project .env file..."
    echo ""
    read -p "Enter your Obsidian API key: " API_KEY

    cat > ".env" << EOF
# Obsidian Vault Skill Configuration
apiKey=$API_KEY
apiUrl=https://localhost:27124
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

# Install commands to user-level
install_commands_user_level() {
    echo -e "${GREEN}➜${NC} Installing commands to user level..."
    echo ""

    local commands_dir="$HOME/.claude/commands"
    mkdir -p "$commands_dir"

    # List of commands to install
    local commands=("capture.md" "idea.md" "quick-note.md")

    for cmd in "${commands[@]}"; do
        echo -e "${GREEN}  ↓${NC} Installing $cmd..."
        if [ "$MODE" = "local" ]; then
            cp "$SOURCE_DIR/.claude/commands/$cmd" "$commands_dir/$cmd" 2>/dev/null || echo -e "${YELLOW}⚠️  Warning: $cmd not found${NC}"
        else
            # Remote mode - use download_file
            download_file ".claude/commands/$cmd" "$commands_dir/$cmd" 2>/dev/null || echo -e "${YELLOW}⚠️  Warning: $cmd not found${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}✓${NC} Commands installed successfully!"
    echo ""
    print_section "📍 Commands Installed:"
    echo "     Location: $commands_dir"
    echo ""
    echo "  📝 Available commands:"
    echo "     - /capture  - Smart router for idea and quick-note capture"
    echo "     - /idea     - Capture ideas to Ideas/ folder"
    echo "     - /quick-note - Append to daily note"
    echo ""
}

# Install commands to project-level
install_commands_project_level() {
    echo -e "${GREEN}➜${NC} Installing commands to project level..."
    echo ""

    local commands_dir="./.claude/commands"
    mkdir -p "$commands_dir"

    # List of commands to install
    local commands=("capture.md" "idea.md" "quick-note.md")

    for cmd in "${commands[@]}"; do
        echo -e "${GREEN}  ↓${NC} Installing $cmd..."
        if [ "$MODE" = "local" ]; then
            cp "$SOURCE_DIR/.claude/commands/$cmd" "$commands_dir/$cmd" 2>/dev/null || echo -e "${YELLOW}⚠️  Warning: $cmd not found${NC}"
        else
            # Remote mode - use download_file
            download_file ".claude/commands/$cmd" "$commands_dir/$cmd" 2>/dev/null || echo -e "${YELLOW}⚠️  Warning: $cmd not found${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}✓${NC} Commands installed successfully!"
    echo ""
    print_section "📍 Commands Installed:"
    echo "     Location: $(pwd)/$commands_dir"
    echo ""
    echo "  📝 Available commands:"
    echo "     - /capture  - Smart router for idea and quick-note capture"
    echo "     - /idea     - Capture ideas to Ideas/ folder"
    echo "     - /quick-note - Append to daily note"
    echo ""
}

# Configure API key
configure_api_key() {
    print_section "⚙️  API Key Configuration"
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
}
