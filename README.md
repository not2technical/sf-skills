# Salesforce Skills for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)
[![Salesforce](https://img.shields.io/badge/Salesforce-Flow%20%26%20DevOps-00A1E0.svg)](https://www.salesforce.com/)

> **⚠️ ALPHA VERSION** - This project is in active development and may break at any time. This is an experimental research area exploring AI-assisted Salesforce development workflows.

---

## Overview

A collection of Claude Code skills for Salesforce development, specializing in Flow automation and DevOps workflows.

| Skill | Description |
|-------|-------------|
| **sf-deployment** | Salesforce DevOps automation for deployments and CI/CD |
| **sf-flow-builder** | Flow creation with validation and best practices |
| **skill-builder** | Wizard for creating Claude Code skills |

## Quick Install

```bash
git clone https://github.com/Jaganpro/claude-code-sfskills.git
cd claude-code-sfskills
./scripts/install.sh
```

**Restart Claude Code** after installation to load the skills.

## Usage

```
# Create a Flow
"Create a screen flow for account creation with validation"

# Deploy Metadata
"Deploy my Apex classes to sandbox with tests"

# Create a Skill
"Create a new Claude Code skill for code analysis"
```

## Scripts

All scripts are located in the `scripts/` folder:

| Script | Description |
|--------|-------------|
| `./scripts/install.sh` | Install skills (use `--local` for project-only) |
| `./scripts/upgrade.sh` | Upgrade to latest version |
| `./scripts/uninstall.sh` | Remove all skills |
| `./scripts/sync-skills.sh` | Sync from ~/.claude/skills to repo |

## Prerequisites

- **Claude Code** (latest version)
- **Salesforce CLI** v2.x (`sf` command)
- **Python 3.8+** (optional, for skill-builder validation)

## Documentation

- [sf-deployment](skills/sf-deployment/README.md)
- [sf-flow-builder](skills/sf-flow-builder/README.md)
- [skill-builder](skills/skill-builder/README.md)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Open a Pull Request

## Issues & Support

- [GitHub Issues](https://github.com/Jaganpro/claude-code-sfskills/issues)

## License

MIT License - Copyright (c) 2024-2025 Jag Valaiyapathy

---

**⚠️ Active Research Project** - Expect breaking changes. Contributions and feedback welcome!
