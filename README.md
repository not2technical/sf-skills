# Salesforce Skills for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blue.svg)](https://claude.ai/code)
[![Salesforce](https://img.shields.io/badge/Salesforce-Apex%20%7C%20Flow%20%7C%20DevOps-00A1E0.svg)](https://www.salesforce.com/)

A collection of Claude Code skills for Salesforce development, specializing in Apex code generation, Flow automation, and DevOps workflows.

## ✨ Available Skills

| Skill | Description | Install Command |
|-------|-------------|-----------------|
| **[sf-apex](sf-apex/)** | Apex code generation & review with 150-point scoring | `/plugin install github:Jaganpro/sf-skills/sf-apex` |
| **[sf-flow-builder](sf-flow-builder/)** | Flow creation & validation with 110-point scoring | `/plugin install github:Jaganpro/sf-skills/sf-flow-builder` |
| **[sf-deployment](sf-deployment/)** | DevOps & CI/CD automation using sf CLI v2 | `/plugin install github:Jaganpro/sf-skills/sf-deployment` |
| **[skill-builder](skill-builder/)** | Claude Code skill creation wizard | `/plugin install github:Jaganpro/sf-skills/skill-builder` |

## 🚀 Installation

### Install Individual Skills (Recommended)

Install only the skills you need:

```bash
# Flow development
/plugin install github:Jaganpro/sf-skills/sf-flow-builder

# Apex development
/plugin install github:Jaganpro/sf-skills/sf-apex

# Deployment automation
/plugin install github:Jaganpro/sf-skills/sf-deployment

# Skill creation wizard
/plugin install github:Jaganpro/sf-skills/skill-builder
```

### Install All Skills at Once

Get the complete Salesforce development suite:

```bash
/plugin install github:Jaganpro/sf-skills
```

This installs all 4 skills as a bundle.

### Local Development Install

```bash
git clone https://github.com/Jaganpro/sf-skills.git
cd sf-skills

# Install specific skill
/plugin install ./sf-flow-builder

# Or install all
/plugin install .
```

## 🔗 Skill Dependencies

Some skills work together for a complete workflow:

```
┌─────────────────┐     ┌─────────────────┐
│  sf-flow-builder │────▶│  sf-deployment  │
└─────────────────┘     └─────────────────┘
                              ▲
┌─────────────────┐           │
│     sf-apex     │───────────┘
└─────────────────┘
```

- **sf-flow-builder** and **sf-apex** optionally use **sf-deployment** for deploying to Salesforce orgs
- Each skill works standalone, but will prompt you to install dependencies if needed

## 🔌 Plugin Features

### Automatic Validation Hooks

Each skill includes validation hooks that run automatically when you write files:

| Skill | File Type | Validation |
|-------|-----------|------------|
| sf-flow-builder | `*.flow-meta.xml` | Flow best practices, 110-point scoring, bulk safety |
| sf-apex | `*.cls`, `*.trigger` | Apex anti-patterns, 150-point scoring, TAF compliance |
| skill-builder | `SKILL.md` | YAML frontmatter validation |

Hooks provide **advisory feedback** after writes - they inform but don't block.

### Validation Scoring

**Flow Validation (110 points)**:
- Design & Naming (20 pts)
- Logic & Structure (20 pts)
- Architecture (15 pts)
- Performance & Bulk Safety (20 pts)
- Error Handling (20 pts)
- Security (15 pts)

**Apex Validation (150 points)**:
- Bulkification (25 pts)
- Security (25 pts)
- Testing (25 pts)
- Architecture (20 pts)
- Clean Code (20 pts)
- Error Handling (15 pts)
- Performance (10 pts)
- Documentation (10 pts)

## 📦 Plugin Commands

| Command | Description |
|---------|-------------|
| `/plugin install github:Jaganpro/sf-skills` | Install all skills |
| `/plugin install github:Jaganpro/sf-skills/sf-flow-builder` | Install single skill |
| `/plugin update sf-skills` | Update to latest version |
| `/plugin uninstall sf-skills` | Remove the plugin |
| `/plugin list` | List installed plugins |

## 🔧 Prerequisites

- **Claude Code** (latest version)
- **Salesforce CLI** v2.x (`sf` command, not legacy `sfdx`)
- **Python 3.8+** (optional, for validation hooks)

## Usage Examples

### Apex Development
```
"Generate an Apex trigger for Account using Trigger Actions Framework"
"Review my AccountService class for best practices"
"Create a batch job to process millions of records"
"Generate a test class with 90%+ coverage"
```

### Flow Development
```
"Create a screen flow for account creation with validation"
"Build a record-triggered flow for opportunity stage changes"
"Generate a scheduled flow for data cleanup"
```

### Deployment
```
"Deploy my Apex classes to sandbox with tests"
"Validate my metadata changes before deploying to production"
```

### Skill Creation
```
"Create a new Claude Code skill for code analysis"
```

## What's Included

### sf-flow-builder
- Flow XML generation with API 62.0 (Winter '26)
- 7 flow type templates (Screen, Record-Triggered, Scheduled, etc.)
- 6 reusable subflow patterns
- Strict validation with 110-point scoring
- Auto-Layout support (locationX/Y = 0)
- Integration with sf-deployment

### sf-apex
- 150-point scoring across 8 categories
- Trigger Actions Framework (TAF) enforcement
- 9 production-ready templates
- SOLID principles validation
- Security best practices (WITH USER_MODE, FLS)
- Modern Apex features (null coalescing, safe navigation)

### sf-deployment
- Modern `sf` CLI v2 commands (not legacy sfdx)
- Dry-run validation (`--dry-run`) before deployment
- Test execution with coverage reporting
- Quick deploy for validated changesets
- CI/CD pipeline support

### skill-builder
- Interactive wizard for skill creation
- YAML frontmatter validation
- Bulk skill validation
- Dependency management
- Interactive terminal editor

## Roadmap

### Naming Convention
```
sf-{capability}           # Cross-cutting (apex, flow, admin)
sf-ai-{name}              # AI features (agentforce, copilot)
sf-product-{name}         # Products (datacloud, omnistudio)
sf-cloud-{name}           # Clouds (sales, service)
sf-industry-{name}        # Industries (healthcare, finserv)
```

### 🔧 Cross-Cutting Skills (Planned)
| Skill | Description |
|-------|-------------|
| `sf-admin` | Objects, fields, layouts |
| `sf-security` | Profiles, permissions, sharing |
| `sf-integration` | REST, SOAP, Platform Events |
| `sf-testing` | Test strategy, mocking, coverage |
| `sf-debugging` | Debug logs, Apex replay |

### 🤖 AI & Automation (Planned)
| Skill | Description |
|-------|-------------|
| `sf-ai-agentforce` | Agent Studio, Topics, Actions |
| `sf-ai-copilot` | Einstein Copilot, Prompts |

### 📦 Products (Planned)
| Skill | Description |
|-------|-------------|
| `sf-product-datacloud` | Unified profiles, segments |
| `sf-product-omnistudio` | FlexCards, DataRaptors |

## Repository Structure

```
sf-skills/
├── .claude-plugin/           # Meta-plugin manifest (installs all)
│   ├── plugin.json
│   └── marketplace.json
├── sf-flow-builder/          # Flow skill (standalone plugin)
│   ├── .claude-plugin/
│   ├── hooks/scripts/        # Flow validators
│   ├── skills/sf-flow-builder/SKILL.md
│   ├── templates/
│   └── docs/
├── sf-apex/                  # Apex skill (standalone plugin)
│   ├── .claude-plugin/
│   ├── hooks/scripts/        # Apex validators
│   ├── skills/sf-apex/SKILL.md
│   └── templates/
├── sf-deployment/            # Deployment skill (standalone plugin)
│   ├── .claude-plugin/
│   ├── skills/sf-deployment/SKILL.md
│   └── templates/
└── skill-builder/            # Skill wizard (standalone plugin)
    ├── .claude-plugin/
    ├── hooks/scripts/        # SKILL.md validator
    ├── skills/skill-builder/SKILL.md
    └── scripts/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `/plugin install ./your-skill`
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Issues & Support

- [GitHub Issues](https://github.com/Jaganpro/sf-skills/issues)

## License

MIT License - Copyright (c) 2024-2025 Jag Valaiyapathy
