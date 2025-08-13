# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System

This is a NixOS configuration using flakes with flake-parts architecture. Key commands:

- `just nixos` - Rebuild NixOS system configuration
- `just build <pkg>` - Build a specific package  
- `just run <pkg>` - Run a specific package
- `just format` - Format all code using treefmt
- `just lint` - Lint Nix, shell, Lua, and YAML files
- `just test` - Run unit tests with nix-unit
- `just check` - Run full flake check including builds
- `just check-nixos <host>` - Check specific host configuration
- `just check-hm` - Check home-manager configuration
- `nix flake check` - Verify flake evaluates correctly
- `nix build` - Build default outputs

## Architecture Overview

### Core Structure
- **flake.nix** - Auto-generated from inputs.nix and outputs.nix
- **inputs.nix** - Flake input definitions (run `just flake` to regenerate flake.nix)
- **outputs.nix** - Main flake outputs using flake-parts
- **hax/** - Custom utility functions library
- **hosts/** - Per-host NixOS configurations with hardware configs and keys
- **home/** - Home-manager configuration modules
- **system/** - NixOS system modules
- **common/** - Shared configuration (overlays, stylix theming)
- **secrets/** - Age-encrypted secrets

### Home Manager Integration
This flake provides two entry points for home-manager:
1. NixOS module integration (recommended)
2. Standalone home-manager configuration

Both must be kept in sync when adding new specialArgs or modules.

### Key Components
- **home/agents/** - AI agent configurations (Claude, Cursor, Avante, etc.)
- **home/nixvim/** - Comprehensive Neovim configuration with language support
- **home/gui/** - Desktop environment (Sway, Waybar, theming)
- **home/tui/** - Terminal utilities and shell configuration
- **system/base/** - Core NixOS system configuration

## Development Workflow

### Testing
- Unit tests in `tests/unit/` using nix-unit framework
- Test specific functions: `nix-unit --flake .#tests.systems.x86_64-linux`
- Integration tests planned in `tests/integration/`

### Code Style
- Nix code formatted with nixfmt via treefmt
- Shell scripts: shellcheck + shfmt + shellharden
- Lua: stylua formatting
- YAML: yamlfmt formatting
- Python: black formatting

### Architecture Philosophy
- Modular design with clear separation of concerns
- Heavy use of Nix's functional programming features
- Custom `hax` library for common utilities
- Theming unified through stylix across all applications

### Host Management
Each host has its own directory in `hosts/` with:
- `default.nix` - Host-specific configuration
- `hardware-configuration.nix` - Hardware detection
- `keys/` - SSH keys and certificates
- Optional `meta.nix` for host metadata

### Secrets Management
Uses agenix for secret encryption. Secrets stored in `secrets/` directory.

## Common Issues
- Flake must be regenerated after changing inputs.nix: `just flake`
- NixOS hardware-configuration.nix may need manual updates
- Personal data hardcoded in various places (search for "anuramat", "arsen")
- Some configurations have dual entry points that must stay synchronized

## Key Files to Understand
- `hax/hosts.nix` - Host management utilities (complex, needs refactoring)
- `home/agents/instructions.nix` - AI agent instruction generation  
- `outputs.nix` - Core flake structure and module integration
- `justfile` - Build automation and common tasks