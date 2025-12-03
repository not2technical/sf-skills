#!/bin/bash
#
# Salesforce Flow DevOps Skills - Installation Script
# Author: Jag Valaiyapathy
# License: MIT
#
# Usage: ./scripts/install.sh [--global|--local]
#

set -e

# Get the directory where this script is located and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default installation location (global)
INSTALL_TYPE="global"
SKILLS_DIR="$HOME/.claude/skills"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --local)
      INSTALL_TYPE="local"
      SKILLS_DIR=".claude/skills"
      shift
      ;;
    --global)
      INSTALL_TYPE="global"
      SKILLS_DIR="$HOME/.claude/skills"
      shift
      ;;
    -h|--help)
      echo "Usage: ./install.sh [--global|--local]"
      echo ""
      echo "Options:"
      echo "  --global    Install skills globally (~/.claude/skills) [DEFAULT]"
      echo "  --local     Install skills in current project (.claude/skills)"
      echo "  -h, --help  Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      exit 1
      ;;
  esac
done

echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  Salesforce Flow DevOps Skills - Installation Wizard    ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Claude Code is installed
if [ ! -d "$HOME/.claude" ]; then
  echo -e "${RED}✗ Error: Claude Code not found${NC}"
  echo -e "${YELLOW}  Please install Claude Code first: https://claude.ai/code${NC}"
  exit 1
fi

echo -e "${BLUE}📍 Installation Type:${NC} $INSTALL_TYPE"
echo -e "${BLUE}📁 Target Directory:${NC} $SKILLS_DIR"
echo ""

# Create skills directory if it doesn't exist
mkdir -p "$SKILLS_DIR"

# List of skills to install
SKILLS=("sf-deployment" "sf-flow-builder" "skill-builder")

echo -e "${CYAN}Installing skills...${NC}"
echo ""

# Install each skill
for skill in "${SKILLS[@]}"; do
  TARGET="$SKILLS_DIR/$skill"

  echo -e "${YELLOW}→ Installing $skill...${NC}"

  # Check if skill already exists
  if [ -d "$TARGET" ]; then
    echo -e "${YELLOW}  ⚠ Skill '$skill' already exists at $TARGET${NC}"
    read -p "  Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${BLUE}  ⏭ Skipping $skill${NC}"
      continue
    fi
    echo -e "${YELLOW}  Backing up existing skill...${NC}"
    mv "$TARGET" "$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
  fi

  # Copy skill directory
  if [ -d "$REPO_ROOT/skills/$skill" ]; then
    cp -r "$REPO_ROOT/skills/$skill" "$TARGET"
    echo -e "${GREEN}  ✓ Installed $skill${NC}"
  else
    echo -e "${RED}  ✗ Error: Skill source not found at $REPO_ROOT/skills/$skill${NC}"
    exit 1
  fi
done

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Installation Complete! 🎉                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Setup Python virtual environment for skill-builder (if needed)
echo -e "${CYAN}Setting up Python environment for skill-builder...${NC}"
SKILL_BUILDER_DIR="$SKILLS_DIR/skill-builder"

if command -v python3 &> /dev/null; then
  if [ ! -d "$SKILL_BUILDER_DIR/.venv" ]; then
    echo -e "${YELLOW}→ Creating virtual environment...${NC}"
    python3 -m venv "$SKILL_BUILDER_DIR/.venv"
    echo -e "${GREEN}  ✓ Virtual environment created${NC}"

    # Install dependencies if requirements.txt exists
    if [ -f "$SKILL_BUILDER_DIR/scripts/requirements.txt" ]; then
      echo -e "${YELLOW}→ Installing Python dependencies...${NC}"
      "$SKILL_BUILDER_DIR/.venv/bin/pip" install -q -r "$SKILL_BUILDER_DIR/scripts/requirements.txt"
      echo -e "${GREEN}  ✓ Dependencies installed${NC}"
    fi
  else
    echo -e "${BLUE}  ℹ Virtual environment already exists${NC}"
  fi
else
  echo -e "${YELLOW}  ⚠ Python 3 not found - skill-builder validation scripts will not work${NC}"
  echo -e "${YELLOW}    Install Python 3 to use advanced validation features${NC}"
fi

echo ""
echo -e "${BLUE}📊 Installed Skills:${NC}"
echo -e "  ${GREEN}✓${NC} sf-deployment (v2.1.0)"
echo -e "  ${GREEN}✓${NC} sf-flow-builder (v1.3.0)"
echo -e "  ${GREEN}✓${NC} skill-builder (v2.0.0)"
echo ""

echo -e "${CYAN}🚀 Next Steps:${NC}"
echo -e "  1. ${YELLOW}Restart Claude Code${NC} to load the new skills"
echo -e "  2. Verify installation: Check available skills in Claude Code"
echo -e "  3. Try the skills:"
echo -e "     • ${BLUE}\"Create a Salesforce flow for account updates\"${NC}"
echo -e "     • ${BLUE}\"Deploy my Salesforce metadata to sandbox\"${NC}"
echo -e "     • ${BLUE}\"Create a new Claude Code skill\"${NC}"
echo ""

echo -e "${CYAN}📚 Documentation:${NC}"
echo -e "  • Main README: README.md"
echo -e "  • sf-deployment: $SKILLS_DIR/sf-deployment/README.md"
echo -e "  • sf-flow-builder: $SKILLS_DIR/sf-flow-builder/README.md"
echo -e "  • skill-builder: $SKILLS_DIR/skill-builder/README.md"
echo ""

echo -e "${CYAN}💡 Tips:${NC}"
echo -e "  • Run ${YELLOW}./scripts/upgrade.sh${NC} to update skills to the latest version"
echo -e "  • Run ${YELLOW}./scripts/uninstall.sh${NC} to remove all skills"
echo -e "  • Report issues: https://github.com/Jaganpro/claude-code-sfskills/issues"
echo ""

echo -e "${GREEN}Happy skill building! 🎉${NC}"
