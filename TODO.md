# TODO Items

This document catalogs all TODO, FIXME, XXX, and HACK comments found in the
codebase, organized by complexity and priority.

## High Complexity (System-Level Changes)

### Critical System Configuration

- **scripts/keygen.sh:9** -
  `sudo chown builder:builder "$private" "$public" # TODO hide somewhere in nix`

  - Move binary cache key ownership management into Nix configuration
  - Requires understanding of Nix build system and binary cache setup

- **scripts/keygen.sh:13** - `# TODO root ssh config`

  - Implement proper root SSH configuration for distributed builds
  - Related to known issue mentioned in CLAUDE.md about SSH keys being ignored

### Package Management Architecture

- **home/cli/misc.nix:8** - `# TODO why not use this instead?` (podman services)
  - Evaluate and potentially switch to alternative podman configuration approach
  - Requires testing impact on existing containerization setup

## Medium Complexity (Feature Implementation)

### Package Testing & Integration

- **home/cli/packages.nix:14** - `# TODO euporie (tui jupyter notebooks)`

  - Add TUI Jupyter notebook package to development tools
  - Requires testing integration with existing Jupyter setup

- **home/cli/packages.nix:118** - `croc # TODO test if it needs setup`

  - Test file transfer tool configuration and document setup requirements
  - May need firewall or network configuration

## Low Complexity (Quick Fixes)

### File Organization

- **home/cli/packages.nix:90** - `# misc TODO categorize`

  - Organize miscellaneous packages into logical categories
  - Documentation and organization task

### Bug Fixes

- **scripts/nix_unused.sh:15** - `# TODO escape dot in .nix`

  - Fix regex pattern to properly escape dots
  - Simple shell script bug fix

## Disabled Features (XXX Items)

### Broken GUI Applications

These packages are commented out due to build or functionality issues:

- **home/desktop/gui.nix:81** - `krita` - Not in cache, takes ages to build
- **home/desktop/gui.nix:83** - `mypaint` - Broken package
- **home/desktop/gui.nix:103** - `qtox` - P2P IM client broken
- **home/desktop/gui.nix:104** - `slack` - Broken package

### System Compatibility

- **links/home/.exrc:32** - Vi recovery directory not needed on NixOS
  - Consider removing or conditionally including based on OS

## Priority Recommendations

1. **Immediate (High Impact)**: Fix SSH configuration and binary cache key
   management
2. **Short Term**: Add missing packages and test existing tool configurations
3. **Medium Term**: Code cleanup and documentation improvements
4. **Long Term**: Investigate and fix broken GUI packages

## Notes

- Total actionable items: 16
- Most items are related to package management and configuration optimization
- Several GUI applications are disabled and may need alternative solutions
- System-level TODOs should be prioritized as they affect core functionality
