# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Build and Development Commands

### Core Development Workflow

- `make all` - Complete rebuild: format, nixos rebuild, links, lint
- `make nixos` - Rebuild NixOS configuration with `sudo nixos-rebuild switch`
- `make format` - Format all code using treefmt (nix, lua, shell, yaml, python,
  markdown)
- `make lint` - Check nix files, lua files, shell scripts, yaml files
- `make links` - Install symlinks from `./links` directory
- `nix build ".#neovim"` - Build standalone neovim configuration

### Testing Commands

- `make nvim-expect` - Test neovim build with expect script
- `nix build` - Build current flake configuration
- `treefmt` - Format files using configuration in treefmt.toml

## Architecture Overview

### Flake Structure

This is a multi-host NixOS configuration using flakes with:

- **Host-specific configs**: `/hosts/{hostname}/` - hardware and host-specific
  settings
- **System configuration**: `/system/` - shared NixOS modules (base, local,
  remote)
- **Home-manager config**: `/home/` - user environment and dotfiles
- **Utility functions**: `/hax/` - custom helper functions and abstractions
- **Secrets management**: `/secrets/` - agenix encrypted secrets
- **Common config**: `/common/` - overlays and styling (stylix)

### Key Components

- **Multi-host support**: Configurations for anuramat-ll7, anuramat-root,
  anuramat-t480
- **Dual entrypoints**: Both NixOS module and standalone home-manager
  configurations
- **Local vs Remote**: System configs automatically switch between local/remote
  modules based on `cluster.this.server`
- **Custom abstractions**: Helper functions in `/hax/` for hosts, web, mime, vim
  configurations

### Directory Structure

- `system/base/` - Core system configuration (nix, user, networking, containers)
- `system/local/` - Desktop/laptop specific config (peripherals, remaps)
- `system/remote/` - Server specific configuration
- `home/gui/` - Desktop environment (sway, waybar, terminals)
- `home/tui/` - Terminal applications (bash, git, yazi, search tools)
- `home/nixvim/` - Comprehensive neovim configuration with language support
- `home/llm/` - AI agent configurations (claude, goose, opencode)

### Development Patterns

- **Modular imports**: Each directory has `default.nix` that imports submodules
- **Special args propagation**: Custom args (user, hax, cluster) passed through
  specialArgs
- **Host clustering**: Dynamic host metadata and relationships via `hax.hosts`
- **XDG compliance**: Extensive use of XDG base directory specification
- **Security**: SSH keys and secrets managed via agenix and automatic key
  collection

### Code Style Preferences

This codebase follows minimalist Nix patterns:

- Extensive use of `let...in`, `inherit`, and `with` statements
- Compact constructs and functional style
- Helper functions in `/hax/` for common operations
- Pipe operators (`|>`) used where supported
- Vim folding markers for organization

### Important Notes

- The hostname must match the target machine for proper configuration selection
- SSH configuration for distributed builds requires manual setup in
  `/root/.ssh/config`
- Binary cache keys are automatically collected during rebuild process
- Some GUI packages are disabled due to build issues (see TODO.md)
