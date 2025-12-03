#!/bin/bash
#
# Salesforce Flow DevOps Skills - Upgrade Script
# Author: Jag Valaiyapathy
# License: MIT
#
# Usage: ./scripts/upgrade.sh [--global|--local]
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
      echo "Usage: ./upgrade.sh [--global|--local]"
      echo ""
      echo "Options:"
      echo "  --global    Upgrade global skills (~/.claude/skills) [DEFAULT]"
      echo "  --local     Upgrade local skills (.claude/skills)"
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
echo -e "${MAGENTA}║  Salesforce Flow DevOps Skills - Upgrade Wizard         ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📍 Installation Type:${NC} $INSTALL_TYPE"
echo -e "${BLUE}📁 Skills Directory:${NC} $SKILLS_DIR"
echo ""

# Check if skills directory exists
if [ ! -d "$SKILLS_DIR" ]; then
  echo -e "${RED}✗ Error: Skills directory not found${NC}"
  echo -e "${YELLOW}  Run ./install.sh first to install skills${NC}"
  exit 1
fi

# List of skills to upgrade
SKILLS=("sf-deployment" "sf-flow-builder" "skill-builder")

echo -e "${CYAN}Checking for upgrades...${NC}"
echo ""

# Function to extract version from SKILL.md
get_version() {
  local skill_dir=$1
  if [ -f "$skill_dir/SKILL.md" ]; then
    grep "^version:" "$skill_dir/SKILL.md" | head -1 | sed 's/version: //' | tr -d ' '
  else
    echo "unknown"
  fi
}

# Check current versions
for skill in "${SKILLS[@]}"; do
  CURRENT_DIR="$SKILLS_DIR/$skill"
  SOURCE_DIR="$REPO_ROOT/skills/$skill"

  if [ -d "$CURRENT_DIR" ]; then
    CURRENT_VERSION=$(get_version "$CURRENT_DIR")
    NEW_VERSION=$(get_version "$SOURCE_DIR")

    echo -e "${BLUE}$skill:${NC}"
    echo -e "  Current: $CURRENT_VERSION"
    echo -e "  Available: $NEW_VERSION"

    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
      echo -e "  ${GREEN}→ Upgrade available${NC}"
    else
      echo -e "  ${YELLOW}→ Already up to date${NC}"
    fi
    echo ""
  else
    echo -e "${YELLOW}$skill: Not installed${NC}"
    echo ""
  fi
done

read -p "$(echo -e ${CYAN}Proceed with upgrade? \(y/N\): ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Upgrade cancelled${NC}"
  exit 0
fi

echo ""
echo -e "${CYAN}Upgrading skills...${NC}"
echo ""

# Upgrade each skill
for skill in "${SKILLS[@]}"; do
  TARGET="$SKILLS_DIR/$skill"
  SOURCE="$REPO_ROOT/skills/$skill"

  if [ ! -d "$TARGET" ]; then
    echo -e "${YELLOW}⏭ Skipping $skill (not installed)${NC}"
    continue
  fi

  echo -e "${YELLOW}→ Upgrading $skill...${NC}"

  # Create backup
  BACKUP_DIR="$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
  echo -e "${BLUE}  Creating backup at $BACKUP_DIR${NC}"
  cp -r "$TARGET" "$BACKUP_DIR"

  # Remove old version (except .venv for skill-builder)
  if [ "$skill" == "skill-builder" ] && [ -d "$TARGET/.venv" ]; then
    echo -e "${BLUE}  Preserving Python virtual environment${NC}"
    mv "$TARGET/.venv" "/tmp/skill-builder-venv-temp"
  fi

  rm -rf "$TARGET"

  # Copy new version
  cp -r "$SOURCE" "$TARGET"

  # Restore .venv for skill-builder
  if [ "$skill" == "skill-builder" ] && [ -d "/tmp/skill-builder-venv-temp" ]; then
    mv "/tmp/skill-builder-venv-temp" "$TARGET/.venv"
  fi

  NEW_VERSION=$(get_version "$TARGET")
  echo -e "${GREEN}  ✓ Upgraded to version $NEW_VERSION${NC}"
done

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Upgrade Complete! 🎉                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}🚀 Next Steps:${NC}"
echo -e "  1. ${YELLOW}Restart Claude Code${NC} to load the updated skills"
echo -e "  2. Review ${BLUE}CHANGELOG.md${NC} for new features and changes"
echo ""

echo -e "${CYAN}💡 Backups created:${NC}"
for skill in "${SKILLS[@]}"; do
  BACKUPS=$(ls -d "$SKILLS_DIR/$skill.backup."* 2>/dev/null || true)
  if [ -n "$BACKUPS" ]; then
    echo -e "  • $skill: ${BLUE}$(basename $(ls -t "$SKILLS_DIR/$skill.backup."* 2>/dev/null | head -1))${NC}"
  fi
done
echo ""

echo -e "${GREEN}Upgrade successful! 🚀${NC}"
