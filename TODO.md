# TODO Items

This document categorizes all TODO-style comments found in the codebase by location and estimated complexity.

## NixOS System Configuration (`os/`)

### High Complexity
- `os/generic/common/lang.nix:7` - Move language packages from system to home-manager (requires architectural changes)
- `os/generic/common/nix.nix:64` - Fix SSH key/user being ignored in build machines (upstream bug)
- `os/generic/common/nix.nix:74` - Configure speedFactor and maxJobs for distributed builds
- `os/generic/common/nix.nix:11` - Add missing keys to trusted-public-keys (security configuration)

### Medium Complexity
- `os/generic/common/default.nix:51` - Remove values that mirror defaults (cleanup)
- `os/generic/common/default.nix:87` - Fix DNSSEC configuration that breaks sometimes
- `os/generic/common/builder.nix:10` - Check if builder port opens automatically
- `os/generic/common/builder.nix:14` - Review if builder user needs isNormalUser = true
- `os/generic/common/builder.nix:24` - Add garbage collection and auto-upgrade configuration
- `os/local/misc.nix:6` - Move file contents (refactoring)
- `os/local/misc.nix:16` - Fix broken obs-nvfbc package
- `os/local/default.nix:44` - Move configuration to notes directory
- `os/generic/shell/default.nix:11` - Move shell configuration to home-manager
- `os/generic/shell/profile.sh:4` - Read referenced documentation

### Low Complexity
- `os/generic/default.nix:14` - Clean up unclear comment ("uhh")

## Home Manager Configuration (`home/`)

### High Complexity
- `home/cli/default.nix:28` - Reorganize entire CLI configuration structure
- `home/cli/git/default.nix:35` - Move hardcoded values to configurable options
- `home/cli/git/default.nix:98` - Investigate Jupyter notebook and nbdime integration

### Medium Complexity
- `home/cli/packages.nix:67` - Categorize miscellaneous packages
- `home/cli/packages.nix:76` - Fix potentially broken croc package
- `home/cli/packages.nix:131` - Compare watchman vs entr file watchers
- `home/desktop/gui.nix:66` - Fix krita build issues (not in cache)
- `home/desktop/gui.nix:68` - Fix broken mypaint package
- `home/desktop/gui.nix:88` - Fix broken qtox package
- `home/desktop/gui.nix:89` - Fix broken slack package
- `home/secret.nix:10` - Transition to Rust version
- `home/email.nix:4` - Fix himalaya with protonmail-bridge integration

### Low Complexity
- `home/default.nix:57` - Clarify home-manager.enable purpose
- `home/cli/files/bashrc.sh:39` - Clean up ugly code
- `home/cli/files/xdg_shims.sh:9` - Append old file to new file functionality
- `home/cli/files/bashrc.d/00-misc.sh:3` - Move miscellaneous configurations
- `home/cli/files/bashrc.d/00-misc.sh:29` - Review if VIRTUAL_ENV_DISABLE_PROMPT is needed
- `home/cli/files/bashrc.d/00-misc.sh:31` - Review if NO_AT_BRIDGE is still needed
- `home/cli/files/bashrc.d/99-ps1.sh:13` - Fix tput sgr0 newline eating issue
- `home/cli/files/bashrc.d/00-pandoc.sh:11` - Document --citeproc usage

## Git-related TODOs

### Medium Complexity
- `home/cli/files/bashrc.d/00-gitgud.sh:20` - Rewrite with fewer assumptions using ghq queries
- `home/cli/files/bashrc.d/00-gitgud.sh:236` - Verify GPT-generated awk code
- `home/cli/files/bashrc.d/00-gitgud.sh:256` - Add unpushed commits from other branches with flag

### Low Complexity
- `home/cli/files/bashrc.d/00-gitgud.sh:3` - Reconsider stderr/stdout handling
- `home/cli/files/bashrc.d/00-gitgud.sh:4` - Add more local/readonly variables

## Neovim Configuration (`nvf/` and `legacyNvimConfig/`)

### High Complexity
- `legacyNvimConfig/default.nix:1` - Complete dependency cleanup
- `legacyNvimConfig/default.nix:110` - Decide between nixcats or nvf approach
- `legacyNvimConfig/lua/plugins/adapters/treesitter/init.lua:13` - Fix broken text object swaps
- `legacyNvimConfig/lua/plugins/adapters/dap.lua:3` - Verify DAP configuration works

### Medium Complexity
- `legacyNvimConfig/lua/plugins/adapters/null.lua:63` - Enable statix when pipe operators supported
- `legacyNvimConfig/lua/plugins/init.lua:22` - Abstract away GitHub remote in Nix
- `legacyNvimConfig/lua/plugins/core/ui.lua:2` - Integrate with Stylix theming
- `nvf/ide.nix:19` - Report broken key descriptions upstream

### Low Complexity
- `nvf/base.vim:2` - Remove unnecessary bangs in vim configuration
- `nvf/default.nix:22` - Review mkForce options override approach
- `legacyNvimConfig/default.nix:53` - Add source attribution comment
- `legacyNvimConfig/lua/utils/stl.lua:47` - Add status line components

## Scripts and Other Files

### Medium Complexity
- `scripts/keygen.sh:9` - Move builder ownership configuration to Nix
- `scripts/keygen.sh:13` - Configure root SSH properly
- `scripts/find_unused_nix_files.sh:15` - Escape dots in .nix filenames

### Low Complexity
- `links/home/exrc:32` - Test recovery files directory on non-NixOS systems

## Known Bugs (BUG/XXX Comments)

### High Priority Bugs
- `legacyNvimConfig/lua/plugins/adapters/treesitter/init.lua:3` - E490: no fold found error ([GitHub issue](https://github.com/neovim/neovim/issues/28692))
- `os/generic/common/default.nix:82` - Rebuilds break sometimes ([GitHub issue](https://github.com/NixOS/nixpkgs/issues/180175))
- `home/desktop/swayidle.nix:39` - Duplicate events overwrite definitions ([GitHub issue](https://github.com/nix-community/home-manager/issues/4432))

### Medium Priority Bugs
- `legacyNvimConfig/lua/plugins/lang/markdown.lua:33` - MdMath build doesn't work due to lazy loading
- `home/email.nix:4` - Himalaya doesn't work with protonmail-bridge ([GitHub issue](https://github.com/pimalaya/himalaya/issues/574))

## Notes for Future Reference
- `home/cli/files/xdg_shims.sh:22` - Python history still hardcoded ([GitHub PR](https://github.com/python/cpython/pull/13208))
- `home/cli/git/hooks/prepare-commit-msg:13` - COMMIT_MSG_FILE behavior difference in interactive mode

## Summary Statistics
- **Total TODO-style comments**: 69
- **NixOS configuration TODOs**: 16
- **Home Manager TODOs**: 21  
- **Neovim configuration TODOs**: 13
- **Git-related TODOs**: 6
- **Scripts and other TODOs**: 3  
- **Known bugs**: 6
- **Informational notes**: 3

### By Complexity
- **High complexity**: 12 items (requires architectural changes, upstream fixes, or significant investigation)
- **Medium complexity**: 33 items (requires moderate effort, package fixes, or configuration changes)
- **Low complexity**: 21 items (simple cleanups, documentation, or minor fixes)