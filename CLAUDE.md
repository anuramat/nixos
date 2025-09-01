# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal NixOS flake configuration managing system and home configurations. Uses
NixOS 25.05, home-manager, nixvim, and custom modules. Supports both Linux
(NixOS) and macOS (Darwin) platforms. Email integration via hydroxide for
ProtonMail bridge functionality. Features, comprehensive AI agent support, and
extensive development tooling.

## Key Architecture

### Directory Structure

- `nixos-configurations/` - Per-host NixOS configs (hostname must match directory)
- `home-configurations/` - Standalone home-manager configs
- `nixos-modules/` - NixOS system modules
- `home-modules/` - Home-manager modules (default/heavy/heavy-linux/darwin/linux/standalone)
- `nixvim-modules/` - Neovim configuration modules
- `hax/` - Helper functions library
- `secrets/` - Age-encrypted secrets
- `overlays/` - Package overlays organized by domain (anytype, cursor, forge, ddgmcp, misc)
- `parts/` - Flake-parts modules (treefmt, pre-commit, tests)
- `shared-modules/` - Shared modules (age, stylix)
- `docs/` - Documentation (USERNAME_CUSTOMIZATION.md)
- `tests/integration/` - Integration testing framework
- `PROBLEMS.md` - Known issues and technical debt tracking

### Module Organization

- Default modules: Minimal base configuration
- Heavy modules: Full desktop environment (GUI, agents, editors)
- Heavy-linux modules: Linux-specific heavy configuration with desktop/agents/Sway
- Darwin modules: macOS-specific configuration 
- Linux modules: Linux-specific base configuration
- Platform-specific examples in `home-configurations/` (e.g., `darwin-example.nix`)
- Two entrypoints each for home-manager and nixvim (NixOS module vs standalone)

### Helper Library (hax)

Located in `hax/`, provides utilities:

- `mkDirSet`, `mkImportSet` - Directory-based module imports
- `common.nix` - Core utilities
- `home.nix`, `hosts.nix`, `vim.nix`, `web.nix` - Domain-specific helpers
- Uses Nix pipe operators extensively

### Package Overlays

Overlays are organized in `overlays/default/` by domain:

- `anytype.nix` - Anytype knowledge management application
- `cursor.nix` - Cursor CLI agent for AI pair programming
- `forge.nix` - Forge AI pair programmer for multiple models
- `ddgmcp.nix` - DuckDuckGo MCP server for web search capabilities
- `misc.nix` - Miscellaneous package overlays and utilities
- `default.nix` - Main overlay orchestrator that imports and combines all overlays

The overlay system supports flakes, unstable packages, Python packages, and npx-based CLI tools.

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

# Run integration tests for username configuration
just test-integration

# Create configuration snapshots before refactoring
just test-snapshot

# Test build matrix with different usernames
just test-matrix

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
4. Configure user via `userConfig` module (see Username Customization below)

### Username Customization

The system supports configurable usernames via the `userConfig` module:

```nix
{
  userConfig = {
    username = "alice";
    fullName = "Alice Smith";  # Optional: defaults to git.userName
    email = "alice@example.com";  # Optional: defaults to git.userEmail
  };
}
```

- Personal home modules auto-load from `home-modules/${username}.nix`
- Git settings provide fallback defaults for fullName/email
- See `docs/USERNAME_CUSTOMIZATION.md` for complete guide

### Secrets Management

Uses ragenix for secrets. Encrypted files in `secrets/` with configuration in `secrets/secrets.nix`.

### Email Configuration

The heavy module includes email support via hydroxide (ProtonMail bridge):
- Himalaya CLI email client with ProtonMail integration
- Hydroxide service for ProtonMail bridge functionality
- Requires manual authentication: `hydroxide auth`, then save to `pass hydroxide`
- IMAP on port 1143, SMTP on port 1025 (localhost)

### AI Agent Integration

The heavy-linux configuration includes comprehensive AI agent support:
- Multiple agent frontends: Claude, Codex, Cursor, Avante, Forge, Gemini, Goose, OpenCode
- MCP server integration for enhanced tool capabilities (including DuckDuckGo search)
- Agent tools and sandbox environments
- Custom agent instructions and role configurations
- Command-line AI assistance via mods

### MIME Type Management

The heavy-linux module includes comprehensive MIME type associations in `home-modules/heavy-linux/mime/`:
- Automatic application associations for text, images, video, documents
- Extensible data-driven configuration via CSV files in `data/` directory
- Smart defaults with application-specific overrides
- Support for custom schemes (magnet links, directories)

## Testing Strategy

### Unit Tests
Tests are in `tests/` directory, run via nix-unit. Test files mirror module structure:
- `tests/hax/` - Helper library tests
- `tests/home-modules/lib/` - Home-manager module library tests (activation-scripts)

### Integration Tests
Located in `tests/integration/`, focused on username configuration:
- `username.nix` - Unit tests for username configuration
- `build-matrix.sh` - Tests building all host configurations
- `snapshot-username.sh` - Captures configuration state for comparison
- `snapshots/` - Baseline snapshots for regression testing

### Testing Workflow
1. Before refactoring: `just test-snapshot`
2. During development: `just test` after each change
3. Build validation: `just test-matrix`
4. Compare results: `./tests/integration/snapshots/compare.sh`

## Key Variables

- Username: Configurable via `userConfig.username` (defaults to `anuramat` for backward compatibility)
- Default system: `x86_64-linux`
- Builder user: `builder`
- Cache key: `/etc/nix/cache.pem.pub`

## Git Configuration

Git is configured with a modular structure in `home-modules/default/git/`:

- `default.nix` - Core git settings, aliases, and GitHub CLI configuration
- `difft.nix` - Difftastic syntax highlighting with smart file skipping
- `ignores.nix` - Comprehensive .gitignore patterns for various languages/tools
- `jupyter.nix` - Jupyter notebook diff/merge support with nbdime
- `worktrees.nix` - Git worktree management with `gwt` command

Key features:

- Difftastic for syntax-aware diffs (auto-skips e.g. lock files)
- GitHub CLI with copilot integration
- Jupyter notebook merge/diff support
- Git worktree management with interactive creation (`gwt` command)
- Extensive aliases (st=status, lg=log graph, ds=diff staged, etc.)
- Smart pager with file separator navigation

## Documentation

- `CLAUDE.md` - This file; project guidance for Claude Code (symlinked as `AGENTS.md`)
- `docs/USERNAME_CUSTOMIZATION.md` - Complete guide for username configuration
- `PROBLEMS.md` - Technical debt and known issues tracking
- `tests/integration/README.md` - Integration testing documentation

## Development Notes

1. Always verify hostname matches directory name before rebuilding
2. SSH keys and cache keys are stored in repo under `nixos-configurations/<hostname>/keys/`
3. Use `just` commands when available for consistency
4. Pipe operators (`|>`) are used throughout - ensure experimental features enabled
5. Tests should pass before committing (`just test`)
6. Run linters before committing (`just lint`)
7. Format code with `just format` or `nix fmt`
