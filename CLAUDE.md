# Memory

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Overview

This is a sophisticated NixOS configuration system managing multiple machines
using Nix flakes and Home Manager. The repository follows a layered, modular
architecture that separates system-level OS configuration from user-level home
configuration.

## Core Architecture

### Configuration Layers

- **Common** (`common/`): Shared configurations (Stylix theming, overlays)
- **System Base** (`system/base/`): Core OS modules (builder, network, user,
  etc.)
- **Local/Remote** (`system/local/`, `system/remote/`): Environment-specific
  configs (desktop vs server)
- **Machine-specific** (`hosts/`): Hardware and unique settings per machine
- **Home Manager** (`home/`): User-level configurations (Sway, Neovim, shell
  setup)

### Machine Classification

Each machine in `hosts/` has a `meta.nix` defining its role:

- `server = true` → gets `system/remote/` (minimal server setup)
- `server = false` → gets `system/local/` (full desktop environment)

### Cluster Management

The system automatically creates a cluster of all machines with:

- SSH host key sharing and binary cache distribution
- Distributed builds between machines
- Automatic SSH aliases (hostname without username prefix)

## Essential Commands

### Primary Development Workflow

```bash
make all          # Full rebuild: format + nixos + links + lint
make nixos        # Core system rebuild (copy keys + nixos-rebuild switch)
make links        # Install symlinks from links/ directory structure
make lint         # Run linting checks (nix disabled + lua + shell + yaml)
make format       # Format code using treefmt
make nvim-expect  # Build Neovim and use expect to show first screen (debugging)
```

### Initial Setup (New Machine)

```bash
# Manual initialization (no make target):
./scripts/guard.sh     # Guard prompt for confirmation
./scripts/keygen.sh    # SSH key and binary cache key generation
# Manual steps after init:
wal sex xterm     # Set basic theme to compile templates
nvim              # Fetch plugins, install TreeSitter parsers
gh auth login     # GitHub CLI authentication
git remote set-url origin git@github.com:anuramat/nixos
sudo tailscale up "--operator=$(whoami)"
```

### Code Quality Tools

```bash
make lint         # Run all linting checks (nix + lua + shell + yaml + misc)
                  # - Nix linting disabled due to pipe operator support issues
                  # - Lua linting with luacheck
                  # - Shell linting with shellcheck  
                  # - YAML validation with yamllint and checkmake
```

### Testing and Validation

```bash
sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --show-trace
# Full system rebuild with experimental pipe operators and detailed trace output
```

## Key Technologies

### Nix Flake Inputs

- Multiple nixpkgs channels (stable 25.05, unstable, old 24.11)
- Home Manager (release-25.05) for user configurations
- Stylix (release-25.05) for system-wide theming
- Hardware-specific modules (nixos-hardware)
- Custom packages (subcat, ctrlsn, mcp-nixos, codex)
- Development tools (neovim-nightly-overlay, nil, nixvim, mdmath)
- Utility and theming (flake-utils, agenix, spicetify-nix, tt-schemes)

### Desktop Environment (Local Machines)

- **Wayland + Sway**: Tiling window manager with custom keybindings
- **Waybar**: Custom status bar configuration
- **Application Suite**: LibreWolf, Zathura, MPV, development tools
- **MIME Management**: Comprehensive MIME type associations with XDG defaults

### Development Tools

- **Neovim**: Built with nixvim (community neovim configuration framework),
  featuring LSP, DAP, TreeSitter, and plugins
  - Configuration in `home/nixvim/default.nix` using nixvim modules
  - FzfLua integration for fuzzy finding with custom keymaps
- **Shell**: Bash with FZF, Zoxide, custom functions and aliases
- **Languages**: Comprehensive support for Nix, Lua, Go, Haskell, Python (with
  MCP), etc.
- **AI Tools**: Claude Code integration with custom commands and permissions

## Important Notes

### Hardcoded Values to Update

When adapting this configuration:

- Personal data in user settings (`anuramat`, `x@ctrl.sn`)
- Home directory paths (`~/notes`, `~/books`)
- SSH keys and cache paths (`/etc/nix/cache.pem`)

### Known Issues

- SSH keys in `nix.buildMachines` are ignored due to upstream bug
- Manual SSH config required in `/root/.ssh/config` for distributed builds
- Transitioning from legacy symlinks to Home Manager (some configs in both
  places)

### Special Features

- Uses Nix pipe operators (`|>`) - requires
  `--option extra-experimental-features pipe-operators`
- Binary cache generation and sharing between machines
- Automatic hardware detection and optimization per machine type
- Integrated password manager and security tools (fail2ban, GPG)
- Claude Code integration with custom commands and permissions in
  `links/home/.claude/`

## File Organization

### Application Configurations

- `links/config/`: Dotfiles and application configs (Jupyter, shell, etc.)
- `links/bin/`: Custom scripts and utilities (aider, todo, lua-to-nix, etc.)
- `links/home/`: User home directory symlinks (mostly empty)
- `home/`: Home Manager modules for user environment
- `home/sway/`: Complete Wayland desktop environment setup
- `home/mime/`: MIME type associations and XDG default applications

### System Configuration

- `system/base/`: Core system packages and services
- `hosts/`: Per-machine hardware and specific settings
- `hax/`: Utility functions used across configurations
- `home/nixvim/`: Neovim configuration using nixvim framework

### Scripts and Maintenance

- `scripts/`: Setup and maintenance scripts
- `Makefile`: Primary interface for build and development commands

## Development Patterns

### Current Machines

The repository currently manages three machines:

- **anuramat-ll7**: Desktop machine (server = false)
- **anuramat-root**: Server machine (server = true) with web services
- **anuramat-t480**: ThinkPad T480 laptop (server = false)

### Adding New Machines

1. Create directory in `hosts/` matching hostname
2. Add `default.nix` with machine-specific configuration
3. Generate `hardware-configuration.nix` using nixos-generate-config
4. Create `meta.nix` with `{ server = true/false; }` to determine role
5. Add SSH keys to `keys/` subdirectory

### Neovim Configuration Structure

- Built using nixvim (community neovim configuration framework) for declarative
  configuration
- Configuration defined in `home/nixvim/default.nix` with nixvim modules and
  options
- FzfLua integration with custom leader key mappings (`<leader>f*`)
- Base vim configuration in `home/nixvim/base.vim` for fundamental settings

### Claude Code Integration

The repository includes full Claude Code integration with:

- **Configuration**: `home/llm/claude.nix` contains Claude Code integration
- **Custom Commands**: `update.md` for automated CLAUDE.md memory updates via
  git diff analysis
- **Permissions**: Carefully configured permissions for safe AI assistance
- **Global Instructions**: User preferences in `~/.claude/CLAUDE.md` for git
  workflow and commit practices
- **Memory Management**: Automated documentation updates using git history
  analysis
