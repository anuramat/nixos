# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a sophisticated NixOS configuration system managing multiple machines using Nix flakes and Home Manager. The repository follows a layered, modular architecture that separates system-level OS configuration from user-level home configuration.

## Core Architecture

### Configuration Layers
- **Common** (`common/`): Shared configurations across all machines (Stylix theming)
- **Generic** (`os/generic/`): Base OS modules (CLI tools, languages, virtualization)
- **Local/Remote** (`os/local/`, `os/remote.nix`): Environment-specific configs (desktop vs server)
- **Machine-specific** (`os/machines/`): Hardware and unique settings per machine
- **Home Manager** (`home/`): User-level configurations (Sway, Neovim, shell setup)

### Machine Classification
Each machine in `os/machines/` has a `meta.nix` defining its role:
- `server = true` → gets `os/remote.nix` (minimal server setup)
- `server = false` → gets `os/local/` (full desktop environment)

### Cluster Management
The system automatically creates a cluster of all machines with:
- SSH host key sharing and binary cache distribution
- Distributed builds between machines
- Automatic SSH aliases (hostname without username prefix)

## Essential Commands

### Primary Development Workflow
```bash
make all          # Full rebuild: flake + links + code quality checks
make flake        # Core system rebuild (copy keys + nixos-rebuild switch)
make code         # Run all formatting and linting (nix + lua + shell)
```

### Initial Setup (New Machine)
```bash
make init         # Guard prompt + SSH key generation
# Manual steps after init:
wal sex xterm     # Set basic theme
nvim              # Fetch plugins, install TreeSitter parsers
gh auth login     # GitHub CLI authentication
git remote set-url origin git@github.com:anuramat/nixos
sudo tailscale up "--operator=$(whoami)"
```

### Code Quality Tools
```bash
make nix          # Format with nixfmt (linting disabled due to pipe operators)
make lua          # Format with stylua + lint with luacheck
make sh           # Format with shfmt + lint with shellcheck
make misc         # YAML formatting and linting
```

## Key Technologies

### Nix Flake Inputs
- Multiple nixpkgs channels (stable 25.05, unstable, old 24.11)
- Home Manager for user configurations
- Stylix for system-wide theming
- Hardware-specific modules (nixos-hardware)
- Custom packages (subcat, ctrlsn, mcp-nixos)

### Desktop Environment (Local Machines)
- **Wayland + Sway**: Tiling window manager with custom keybindings
- **Waybar**: Custom status bar configuration
- **Application Suite**: LibreWolf, Zathura, MPV, development tools

### Development Tools
- **Neovim**: Heavily customized with LSP, DAP, TreeSitter, and plugins
- **Shell**: Bash with FZF, Zoxide, custom functions and aliases
- **Languages**: Comprehensive support for Nix, Lua, Go, Haskell, Python, etc.

## Important Notes

### Hardcoded Values to Update
When adapting this configuration:
- Personal data in user settings (`anuramat`, `x@ctrl.sn`)
- Home directory paths (`~/notes`, `~/books`)
- SSH keys and cache paths (`/etc/nix/cache.pem`)

### Known Issues
- SSH keys in `nix.buildMachines` are ignored due to upstream bug
- Manual SSH config required in `/root/.ssh/config` for distributed builds
- Transitioning from legacy symlinks to Home Manager (some configs in both places)

### Special Features
- Uses Nix pipe operators (`|>`) - requires `--option extra-experimental-features pipe-operators`
- Binary cache generation and sharing between machines
- Automatic hardware detection and optimization per machine type
- Integrated password manager and security tools (fail2ban, GPG)

## File Organization

### Application Configurations
- `config/`: Dotfiles and application configs (Neovim, Jupyter, shell, etc.)
- `home/`: Home Manager modules for user environment
- `home/sway/`: Complete Wayland desktop environment setup

### System Configuration
- `os/generic/common/`: Core system packages and services
- `os/machines/`: Per-machine hardware and specific settings
- `helpers/`: Utility functions used across configurations

### Scripts and Maintenance
- `scripts/`: Setup and maintenance scripts
- `Makefile`: Primary interface for build and development commands