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

Overlays are organized in `overlays/default/` by domain and are orchestrated via `default.nix`:

- Flake-based overlays for agent tools and MCP servers (e.g., DuckDuckGo MCP, Claude Desktop, Mods, Zotero MCP, Subcat, Gothink, Todo)
- Unstable package overlays for bleeding-edge tools (e.g., github-mcp-server, keymapp, proton-pass, goose-cli)
- Python package overrides for markdown formatting (e.g., mdformat-deflist)
- Shell wrappers for agent CLIs (Qwen, Gemini, Opencode, Claude Monitor, Inspector, CCUsage)
- Modular orchestration of overlays from a wide set of sources, including custom and forked projects

The overlay system supports flakes, unstable packages, Python packages, npx/bunx-based CLI tools, and impure wrappers for agent binaries.

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
    fullName = "Alice Smith"; # Optional: defaults to git.userName
    email = "alice@example.com"; # Optional: defaults to git.userEmail
  };
}
```

- Personal home modules auto-load from `home-modules/${username}.nix`
- Git settings provide fallback defaults for fullName/email

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

- Multiple agent frontends: Opencode, Claude, Codex, Qwen, Avante, Cursor, Forge, Gemini, Goose
- Sandboxed wrappers for agent binaries (e.g., ocd, cld, cdx, qwn, gmn, gse)
- Per-agent configuration files (JSON, TOML, YAML) for settings, MCP server integration, and context files (AGENTS.md)
- Notification hooks and session variables for agent environments
- Sophisticated roles and prompts (e.g., academic summarizer, tool restrictions)
- Neovim integration for Avante via MCP hub
- Home activation scripts generate config files for agents and MCP servers
- MCP server integration for enhanced tool capabilities (including DuckDuckGo search)
- Command-line AI assistance via mods

### MIME Type Management

The heavy-linux module includes comprehensive MIME type associations in `home-modules/heavy-linux/desktop/mime/`:

- Data-driven MIME configuration using CSV files for extensibility (audio, text, font, video, image)
- Centralized module assigns default applications for all major MIME types
- Special handling for magnet links and directories
- Integrated into the desktop environment for NixOS
- Smart defaults with application-specific overrides

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
- `difft.nix` - Difftastic integration for syntax-aware diffs, with auto-skip for files marked `-diff` in .gitattributes
- `ignores.nix` - Comprehensive .gitignore patterns for various languages/tools
- `jupyter.nix` - Jupyter notebook diff/merge support with nbdime
- `worktrees.nix` - Git worktree management with `gwt` command

Key features:

- Difftastic for syntax-aware diffs (auto-skips e.g. lock files)
- Extensive git and GitHub CLI aliases and extensions
- Jupyter notebook merge/diff support
- Git worktree management with interactive creation (`gwt` command)
- Smart pager navigation for diffs using invisible separator

## Language Modules

The heavy language module provides a full suite of compilers, linters, formatters, debuggers, and code utilities for multiple languages:

- Compilers: Go, Haskell, Rust, Julia, C/C++, Lua, Node, Bun, Perl, Ruby, Sage, etc.
- Linters: Nix, Go, Lua, Shell, YAML
- Formatters: Python, Go, Haskell, HTML, Markdown (with plugins), Nix, Shell, Lua, YAML
- Debuggers: Go, C, Python
- Miscellaneous tools for code search, JSON/YAML/HTML processing, dependency graphing, notebook conversion, type generation
- Python and YAML modules imported for extended support

## Documentation

- `AGENTS.md` - This file; project guidance for AI agents
- `docs/USERNAME_CUSTOMIZATION.md` - Complete guide for username configuration
- `PROBLEMS.md` - Technical debt and known issues tracking
- `tests/integration/README.md` - Integration testing documentation

## Flake Inputs & Overlays

The flake inputs now include a wide range of overlays and MCP servers for agents, markdown formatting, math, and desktop integration:

- Flake-based overlays for agent tools and MCP servers (e.g., DuckDuckGo MCP, Claude Desktop, Mods, Zotero MCP, Subcat, Gothink, Todo)
- Custom overlays for personal and forked projects (e.g., ctrlsn, figtree, mdformat-myst, mdmath, mods, zotero-mcp)
- Inputs for neovim-nightly, NUR, nixpkgs-unstable, home-manager, stylix, treefmt, git-hooks, ez-configs, and more
- Modular and extensible input organization for overlays and MCP servers

## Development Notes

1. Always verify hostname matches directory name before rebuilding
2. SSH keys and cache keys are stored in repo under `nixos-configurations/<hostname>/keys/`
3. Use `just` commands when available for consistency
4. Pipe operators (`|>`) are used throughout - ensure experimental features enabled
5. Tests should pass before committing (`just test`)
6. Run linters before committing (`just lint`)
7. Format code with `just format` or `nix fmt`
