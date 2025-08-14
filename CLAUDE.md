# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal NixOS configuration flake managing system and home configurations for multiple machines (anuramat-ll7, anuramat-root, anuramat-t480).

## Architecture

### Core Structure
- `flake.nix`: Entry point importing outputs.nix
- `outputs.nix`: Main flake configuration using flake-parts
- `inputs.nix`: Flake inputs (regenerated into flake.nix)
- `hax/`: Custom helper functions and utilities
- `nixos-configurations/`: Per-host NixOS configurations
- `home-configurations/`: Home-manager configurations
- `home-modules/`: Modular home-manager config components
- `nixos-modules/`: Modular NixOS config components
- `secrets/`: Age-encrypted secrets managed with ragenix
- `overlays/`: Package overlays
- `stylix/`: Theming configuration
- `tests/`: Unit tests

### Key Modules
- `home-modules/default/nixvim/`: Neovim configuration
- `home-modules/default/agents/`: AI agent configurations (Claude, Cursor, etc.)
- `home-modules/default/gui/desktop/sway/`: Sway WM configuration
- `home-modules/default/tui/`: Terminal utilities and configs

## Development Commands

### Build & Deploy
```bash
just nixos          # Rebuild and switch system configuration
just flake          # Regenerate flake.nix from inputs.nix
just all            # Run full build pipeline (flake, format, test, lint, nixos)
```

### Code Quality
```bash
just format         # Format all code (nix, lua, shell, yaml, python)
just lint           # Run linters (luacheck, shellcheck, yamllint)
just test           # Run unit tests
just test --quiet   # Run tests quietly
```

### Utilities
```bash
just build <pkg>    # Build a specific package
just run <pkg>      # Run a specific package
just check-nixos    # Check current host configuration
just check-nixos <host>  # Check specific host configuration
just check-hm       # Check home-manager configuration
```

### Nix Commands
```bash
nix flake check     # Check flake validity
nix fmt             # Format nix files
nix-unit --flake .#tests.systems.x86_64-linux  # Run tests
```

## Important Conventions

### Flake Management
- `inputs.nix` is the source of truth for flake inputs
- Run `just flake` after modifying inputs.nix to regenerate flake.nix
- All inputs follow nixpkgs where possible

### Secrets
- Encrypted with age/ragenix
- Located in `/secrets/` directory
- Access via `config.age.secrets.<name>.path`

### Testing
- Unit tests in `/tests/` directory
- Run with `just test` or `nix-unit`
- Test specific architectures with arch parameter

### Module System
- Home configurations have 2 entrypoints: NixOS module and standalone
- Nixvim has 2 entrypoints: home-manager module and standalone
- New specialArgs and modules must be added to both entrypoints

### User Configuration
- Primary user: "anuramat"
- Builder user: "builder"
- User data defined in outputs.nix

## Known Issues
- Builder setup requires manual SSH config in /root/.ssh/config
- Some hardcoded paths (~/notes, ~/books)
- `..` imports in /secrets directory