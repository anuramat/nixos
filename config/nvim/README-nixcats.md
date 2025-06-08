# NixCats + lze Migration

This directory contains the migrated Neovim configuration using [nixcats](https://nixcats.org/) and [lze](https://github.com/BirdeeHub/lze) instead of lazy.nvim.

## Structure

### Key Files

- `init.lua` - Main entry point, detects nixcats vs fallback to lazy.nvim
- `flake.nix` - Standalone nixcats flake (alternative approach)  
- `lua/plugins/nixcats.lua` - Main plugin loader using lze
- `lua/plugins/adapters/*-nixcats.lua` - Migrated adapter configs
- `lua/plugins/core/*-nixcats.lua` - Migrated core plugin configs

### Integration

- `home/editor-nixcats.nix` - NixOS/Home Manager integration
- Modified main `flake.nix` to include nixCats input

## Migration Status

### ✅ Completed

- Basic nixcats flake structure
- Core plugins (oil, surround, etc.)
- Git plugins (fugitive, gitsigns, neogit)
- UI plugins (dressing, colorizer, etc.)
- LSP configuration
- Completion (blink.cmp)
- FZF integration

### 🚧 TODO

- DAP (debugging) configuration
- TreeSitter configuration  
- Language-specific configurations
- LLM/AI plugins (copilot, avante)
- Jupyter/data science plugins
- Custom plugins (wastebin, figtree, etc.)

## Usage

### Option 1: Replace Current Config

```bash
# Backup current config
cp home/editor.nix home/editor-backup.nix

# Switch to nixcats
mv home/editor-nixcats.nix home/editor.nix

# Rebuild
make flake
```

### Option 2: Test Standalone

```bash
# Build nixcats config
cd config/nvim
nix build

# Test the built neovim
./result/bin/nvim
```

### Option 3: Gradual Migration

The current `init.lua` detects if running under nixcats and falls back to
lazy.nvim otherwise, allowing gradual testing.

## Benefits

1. **Reproducible**: All plugins managed by Nix
2. **Faster startup**: No plugin downloads at runtime
3. **Better dependency management**: LSP servers, formatters included
4. **Declarative**: Plugin versions pinned in flake.lock
5. **Modular**: Categories allow different configurations per machine

## Plugin Categories

- `general`: Core plugins always loaded
- `treesitter`: Syntax highlighting and text objects
- `git`: Git integration plugins  
- `lazy`: Plugins that can be lazy-loaded with lze

## Notes

- Some custom/newer plugins may need to be added to nixpkgs
- Python/Lua dependencies are properly managed
- LSP servers and tools are included automatically
- Configuration maintains compatibility with existing key bindings and workflows
