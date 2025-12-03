#!/bin/bash
#
# Salesforce Flow DevOps Skills - Uninstall Script
# Author: Jag Valaiyapathy
# License: MIT
#
# Usage: ./scripts/uninstall.sh [--global|--local]
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
      echo "Usage: ./uninstall.sh [--global|--local]"
      echo ""
      echo "Options:"
      echo "  --global    Uninstall global skills (~/.claude/skills) [DEFAULT]"
      echo "  --local     Uninstall local skills (.claude/skills)"
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
echo -e "${MAGENTA}║  Salesforce Flow DevOps Skills - Uninstall Wizard       ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📍 Installation Type:${NC} $INSTALL_TYPE"
echo -e "${BLUE}📁 Skills Directory:${NC} $SKILLS_DIR"
echo ""

# Check if skills directory exists
if [ ! -d "$SKILLS_DIR" ]; then
  echo -e "${YELLOW}⚠ Skills directory not found${NC}"
  echo -e "${BLUE}  Nothing to uninstall${NC}"
  exit 0
fi

# List of skills to uninstall
SKILLS=("sf-deployment" "sf-flow-builder" "skill-builder")

echo -e "${CYAN}Skills to be removed:${NC}"
for skill in "${SKILLS[@]}"; do
  if [ -d "$SKILLS_DIR/$skill" ]; then
    echo -e "  ${RED}✗${NC} $skill"
  else
    echo -e "  ${BLUE}⏭${NC} $skill (not installed)"
  fi
done
echo ""

echo -e "${RED}⚠ WARNING: This will permanently remove all installed skills${NC}"
read -p "$(echo -e ${YELLOW}Are you sure? Type \'yes\' to confirm: ${NC})" CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo -e "${YELLOW}Uninstall cancelled${NC}"
  exit 0
fi

echo ""
echo -e "${CYAN}Uninstalling skills...${NC}"
echo ""

# Uninstall each skill
for skill in "${SKILLS[@]}"; do
  TARGET="$SKILLS_DIR/$skill"

  if [ ! -d "$TARGET" ]; then
    echo -e "${BLUE}⏭ $skill (not installed)${NC}"
    continue
  fi

  echo -e "${YELLOW}→ Removing $skill...${NC}"
  rm -rf "$TARGET"
  echo -e "${GREEN}  ✓ Removed${NC}"
done

# Clean up backup directories (optional)
echo ""
read -p "$(echo -e ${CYAN}Remove backup directories too? \(y/N\): ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  for skill in "${SKILLS[@]}"; do
    BACKUPS=$(ls -d "$SKILLS_DIR/$skill.backup."* 2>/dev/null || true)
    if [ -n "$BACKUPS" ]; then
      echo -e "${YELLOW}→ Removing backups for $skill...${NC}"
      rm -rf "$SKILLS_DIR/$skill.backup."*
      echo -e "${GREEN}  ✓ Removed${NC}"
    fi
  done
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Uninstall Complete                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}All skills have been removed from $SKILLS_DIR${NC}"
echo -e "${YELLOW}Restart Claude Code to complete the removal${NC}"
echo ""

echo -e "${BLUE}Thank you for using Salesforce Flow DevOps Skills! 👋${NC}"
