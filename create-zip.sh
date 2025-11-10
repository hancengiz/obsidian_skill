#!/bin/bash

# Obsidian Vault Skill - Zip Creator for Claude Desktop/Web
# Creates a zip file that can be uploaded to Claude Desktop or claude.ai

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILL_NAME="obsidian-vault-skill"
ZIP_NAME="${SKILL_NAME}.zip"
TEMP_DIR=$(mktemp -d)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Obsidian Vault Skill - Zip Builder"
echo "  For Claude Desktop & claude.ai (Web)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if SKILL.md exists
if [ ! -f "$SCRIPT_DIR/SKILL.md" ]; then
    echo -e "${RED}✗${NC} Error: SKILL.md not found in $SCRIPT_DIR"
    echo "   Make sure you're running this from the obsidian_skill directory"
    exit 1
fi

echo -e "${GREEN}➜${NC} Preparing files for packaging..."

# Create temporary directory structure
mkdir -p "$TEMP_DIR/$SKILL_NAME"

# Copy required files
cp "$SCRIPT_DIR/SKILL.md" "$TEMP_DIR/$SKILL_NAME/"
echo -e "${GREEN}  ✓${NC} SKILL.md"

# Copy optional files if they exist
if [ -f "$SCRIPT_DIR/README.md" ]; then
    cp "$SCRIPT_DIR/README.md" "$TEMP_DIR/$SKILL_NAME/"
    echo -e "${GREEN}  ✓${NC} README.md"
fi

# Copy docs folder if it exists
if [ -d "$SCRIPT_DIR/docs" ]; then
    mkdir -p "$TEMP_DIR/$SKILL_NAME/docs"
    cp -r "$SCRIPT_DIR/docs/"* "$TEMP_DIR/$SKILL_NAME/docs/"
    echo -e "${GREEN}  ✓${NC} docs/ folder"
fi

# Copy .gitignore if it exists
if [ -f "$SCRIPT_DIR/.gitignore" ]; then
    cp "$SCRIPT_DIR/.gitignore" "$TEMP_DIR/$SKILL_NAME/"
    echo -e "${GREEN}  ✓${NC} .gitignore"
fi

echo ""
echo -e "${GREEN}➜${NC} Creating zip file..."

# Create zip file
cd "$TEMP_DIR"
zip -r "$SCRIPT_DIR/$ZIP_NAME" "$SKILL_NAME" > /dev/null

# Clean up
rm -rf "$TEMP_DIR"

# Get file size
FILE_SIZE=$(du -h "$SCRIPT_DIR/$ZIP_NAME" | cut -f1)

echo -e "${GREEN}✓${NC} Zip file created successfully!"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦 Package Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "  ${GREEN}✓${NC} File: $ZIP_NAME"
echo -e "  ${GREEN}✓${NC} Size: $FILE_SIZE"
echo -e "  ${GREEN}✓${NC} Location: $SCRIPT_DIR"
echo ""
echo "  Contents:"
unzip -l "$SCRIPT_DIR/$ZIP_NAME" | tail -n +4 | head -n -2 | sed 's/^/    /'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 Installation Instructions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}For Claude Desktop:${NC}"
echo "  1. Open Claude Desktop"
echo "  2. Go to Settings → Capabilities"
echo "  3. Click \"Upload skill\""
echo "  4. Select: $SCRIPT_DIR/$ZIP_NAME"
echo "  5. Enable the skill"
echo ""
echo -e "${BLUE}For claude.ai (Web):${NC}"
echo "  1. Go to https://claude.ai"
echo "  2. Click Settings (gear icon)"
echo "  3. Go to Capabilities tab"
echo "  4. Click \"Upload skill\""
echo "  5. Select: $SCRIPT_DIR/$ZIP_NAME"
echo "  6. Enable the skill"
echo ""
echo -e "${YELLOW}⚠️  Requirements:${NC}"
echo "  • Pro, Max, Team, or Enterprise plan"
echo "  • Code execution must be enabled"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚙️  Configuration (After Upload):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The skill needs your Obsidian API key to work."
echo ""
echo "Create a config file in one of these locations:"
echo ""
echo "  1. Project .env file (in your working directory):"
echo "     "
echo "     apiKey=your-api-key-here"
echo "     apiUrl=http://localhost:27123"
echo "     allowDelete=false"
echo ""
echo "  2. User config file (~/.cc_obsidian/config.json):"
echo "     "
echo "     {"
echo "       \"apiKey\": \"your-api-key-here\","
echo "       \"apiUrl\": \"http://localhost:27123\","
echo "       \"allowDelete\": false,"
echo "       \"backupEnabled\": true,"
echo "       \"backupDirectory\": \"~/.cc_obsidian/backups\","
echo "       \"backupKeepLastN\": 5,"
echo "       \"DANGEROUSLY_SKIP_CONFIRMATIONS\": false"
echo "     }"
echo ""
echo "  3. Or use environment variables (platform-dependent):"
echo "     "
echo "     export OBSIDIAN_SKILL_API_KEY=\"your-api-key-here\""
echo "     export OBSIDIAN_SKILL_API_URL=\"http://localhost:27123\""
echo ""
echo "Get your API key from:"
echo "  Obsidian → Settings → Community Plugins → Local REST API"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✨ Package ready for upload!${NC}"
echo ""
