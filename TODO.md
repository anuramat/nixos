# TODO Items

This document categorizes all TODO, FIXME, XXX, and HACK comments found in the codebase by implementation complexity.

## 🔥 High Complexity (Major Features/Refactoring)

### System Architecture
- **nixcats or nvf**: `home/editor.nix:3` - Major decision on Neovim configuration framework
- **Move to rust version**: `home/secret.nix:10` - Transition password-store to rust implementation
- **Transitioning from legacy symlinks to Home Manager**: Multiple locations - Large refactoring effort

### Feature Development
- **Mathematica setup**: `os/generic/common/lang.nix:74-75` - Move complex Mathematica installation notes to documentation
- **idlehint implementation**: `home/desktop/swayidle.nix:38` - Requires upstream contribution to Home Manager
- **events working properly**: `home/desktop/swayidle.nix:40` - Fix Home Manager events issue (#4432)

## 🟡 Medium Complexity (Configuration/Enhancement)

### Application Configuration
- **Waybar cleanup**: `home/desktop/waybar/config:1` - Remove unused waybar modules
- **Stylix transparency**: `nvim/lua/plugins/core/ui.lua:2` - Integrate transparent background with Stylix theming
- **Categorize packages**: `home/cli/packages.nix:65` - Organize miscellaneous CLI packages
- **Felix file manager picker**: `home/cli/packages.nix:59,62` - Waiting for upstream feature
- **Watchman vs entr comparison**: `home/cli/packages.nix:134` - Evaluate file watchers

### Development Tools
- **Task file environment variable**: `links/bin/todo:11` - Make todo file location configurable
- **Task date handling**: `links/bin/todo:23,195` - Auto-append dates and sort by date
- **croc stability**: `home/cli/packages.nix:73` - Fix or replace file transfer tool

## 🟢 Low Complexity (Minor Fixes/Cleanup)

### Code Quality
- **Broken packages**: `os/local/default.nix:99,101` `os/local/misc.nix:12,13` - Fix or remove broken packages (krita, mypaint, qtox, slack)
- **NetworkManager hack**: `os/generic/common/default.nix:79` - Document or resolve NetworkManager wait-online workaround

### Comments and Documentation
- **Unused file removal**: Multiple locations - Clean up unused configuration files
- **Duplicate file manager entries**: `home/cli/packages.nix:61,63` - Remove duplicate yazi, felix-fm, nnn package entries

## 📊 Summary

- **Total TODOs found**: ~20 items
- **High complexity**: 6 items (30%)
- **Medium complexity**: 8 items (40%) 
- **Low complexity**: 6 items (30%)

## Notes

- Most TODOs are related to package management and configuration cleanup
- Several items depend on upstream fixes or features
- Major architectural decisions (nixcats vs nvf, rust password-store) need evaluation
- Regular maintenance items include broken package cleanup and dependency updates