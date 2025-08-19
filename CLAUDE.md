# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal NixOS flake configuration managing system and home configurations. Uses NixOS 25.05, home-manager, nixvim, and custom modules.

## Key Architecture

### Directory Structure
- `nixos-configurations/` - Per-host NixOS configs (hostname must match directory)
- `home-configurations/` - Standalone home-manager configs
- `nixos-modules/` - NixOS system modules
- `home-modules/` - Home-manager modules (default/heavy/standalone)
- `nixvim-modules/` - Neovim configuration modules
- `hax/` - Helper functions library
- `secrets/` - Age-encrypted secrets
- `parts/` - Flake-parts modules (treefmt, pre-commit, tests)

### Module Organization
- Default modules: Minimal base configuration
- Heavy modules: Full desktop environment (GUI, agents, editors)
- Two entrypoints each for home-manager and nixvim (NixOS module vs standalone)

### Helper Library (hax)
Located in `hax/`, provides utilities:
- `mkDirSet`, `mkImportSet` - Directory-based module imports
- `common.nix` - Core utilities
- `home.nix`, `hosts.nix`, `vim.nix`, `web.nix` - Domain-specific helpers
- Uses Nix pipe operators extensively

## Common Commands

### Build & Deploy
```bash
# Full rebuild (formats, tests, lints, rebuilds NixOS)
just all

# NixOS rebuild only
just nixos
# or directly:
sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --show-trace

# Regenerate flake.nix from inputs
just flake

# Format code
just format
# or:
nix fmt
```

### Testing & Validation
```bash
# Run tests
just test
# or with architecture:
nix-unit --flake .#tests.systems.x86_64-linux

# Lint code
just lint

# Check specific configuration
just check-nixos anuramat-ll7
just check-hm anuramat

# Full flake check
nix flake check
```

### Development
```bash
# Build specific package
just build firefox
# or:
nix build ".#nixosConfigurations.$(hostname).pkgs.firefox"

# Run package without installing
just run package-name
```

## Important Patterns

### Pipe Operators
This codebase uses Nix pipe operators (`|>`) extensively. Always enable:
```bash
--option extra-experimental-features pipe-operators
```

### Module Imports
Modules are auto-discovered from directories using `mkImportSet`:
```nix
nixosModules = mkImportSet ./nixos-modules;
```

### Per-Host Configuration
1. Create directory in `nixos-configurations/` matching hostname
2. Add `default.nix` and `hardware-configuration.nix`
3. Store host keys in `keys/` subdirectory

### Secrets Management
Uses ragenix for secrets. Encrypted files in `secrets/` with configuration in `secrets/secrets.nix`.

## Testing Strategy

Tests are in `tests/` directory, run via nix-unit. Test files mirror module structure in `tests/hax/`.

## Key Variables
- Username: `anuramat` (hardcoded in several places)
- Default system: `x86_64-linux`
- Builder user: `builder`
- Cache key: `/etc/nix/cache.pem.pub`

## Development Notes

1. Always verify hostname matches directory name before rebuilding
2. SSH keys and cache keys are stored in repo under `nixos-configurations/<hostname>/keys/`
3. Use `just` commands when available for consistency
4. Pipe operators (`|>`) are used throughout - ensure experimental features enabled
5. Tests should pass before committing (`just test`)
6. Run linters before committing (`just lint`)
7. Format code with `just format` or `nix fmt`