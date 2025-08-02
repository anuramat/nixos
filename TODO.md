# TODO List

This list is automatically generated from `rg TODO` and categorized by estimated complexity.

## Hard

- `system/base/default.nix`: Fix what "doesn't work".
- `system/base/default.nix`: Check system behavior through virtualization and potentially move parts of the configuration.
- `system/base/net.nix`: Fix intermittent DNSSEC issue, possibly related to captive portals.
- `home/gui/obs.nix`: Fix the broken `obs-nvfbc` package.
- `home/keyring.nix`: Figure out Rust version or keyring locking issues.
- `home/agents/roles.nix`: Set up a tmux test bench.
- `home/agents/roles.nix`: Perform general refactoring.
- `home/agents/tools.nix`: Integrate nvim mcp for LSP, formatter, etc.
- `home/agents/tools.nix`: Implement RAG (Retrieval Augmented Generation).
- `hax/hosts.nix`: Refactor the entire file ("this mess").
- `home/agents/frontends/goose.nix`: Implement "ALL".
- `home/agents/frontends/codex.nix`: Implement "ALL".
- `home/agents/frontends/avante.nix`: Create a patch for the package.
- `home/agents/frontends/default.nix`: Implement mcp, commands, and roles for `avante.nix`.
- `home/agents/frontends/default.nix`: Implement commands, subagents, and mcp for `gemini.nix`.
- `home/agents/frontends/default.nix`: Implement "all" for `goose.nix`.
- `home/agents/frontends/default.nix`: Implement mcp, subagents, commands, and lsp for `opencode.nix`.
- `home/gui/desktop/sway/swayidle.nix`: Implement or request `idlehint` feature upstream.
- `home/tui/git.nix`: Make the broken feature work again.
- `home/tui/bash/git.sh`: Perform a "total rehaul" and move the script.
- `home/mime/default.nix`: Fix the `mimeFromDesktop` function that errors out due to context.

## Medium

- `treefmt.toml`: Enable, format, and verify everything is okay with `treefmt`.
- `outputs.nix`: Check if the flake output builds.
- `inputs.nix`: Try using riskier flake inputs.
- `inputs.nix`: Research if it's possible to only look up nixpkgs stuff in the cache.
- `.gitignore`: Review the entire `.gitignore` file.
- `system/base/builder.nix`: Consider the security implications of `isNormalUser = true;`.
- `hosts/anuramat-root/web/default.nix`: If the current setup works, unboilerplate it with a function.
- `home/nixvim/lang/python.nix`: Investigate and report the bug where `jupytext` doesn't get installed automatically.
- `home/tui/packages.nix`: Add and configure `euporie` (TUI Jupyter notebooks).
- `home/nixvim/lang/go.nix`: Add and configure the `ray-x/go.nvim` plugin.
- `home/nixvim/lang/haskell.nix`: Add and configure Haskell development tools.
- `home/agents/frontends/opencode.nix`: Implement stylix and themeing.
- `home/nixvim/lang/markdown.nix`: Add a snippet wrapping feature for equations.
- `home/tui/bin/todo.py`: Implement sorting by date.
- `home/tui/bin/default.nix`: Refactor root SSH config from `nix.nix`.
- `home/tui/bin/diriger.sh`: Show session details in the prompt/chooser.
- `home/tui/bash/ps1.sh`: Debug the `tput sgr0` newline issue.
- `home/gui/desktop/portals.nix`: Read the Arch Wiki and verify portal configurations.
- `home/nixvim/ide/completion.nix`: Add and configure `ctags-lsp.nvim`.
- `home/tui/git.nix`: Check and configure `nbdime` for Jupyter notebook diffs.
- `home/tui/bash/git.sh`: Add a feature to show unpushed commits from other branches.
- `home/editor.nix`: Refactor editor setup to be plugin-by-plugin.

## Easy

- `outputs.nix`: Use the home-manager specific stylix module.
- `inputs.nix`: Check the documentation for `follows`.
- `inputs.nix`: Understand how `flake = false;` works.
- `inputs.nix`: Check which inputs are in the community cache.
- `inputs.nix`: Use `max-jobs` to fetch caches.
- `common/stylix.nix`: Swap the green and red colors in the theme.
- `hosts/anuramat-ll7/default.nix`: Abstract a value into a `meta.nix` variable.
- `hosts/anuramat-ll7/default.nix`: Research what `vaapiVdpau` does.
- `system/local/default.nix`: Move the configuration to notes.
- `system/base/default.nix`: Decide whether to move the configuration block.
- `system/base/default.nix`: Investigate why `boot.initrd.systemd.enable = true;` is present.
- `system/base/default.nix`: Research what `mount-nvidia-executables = true;` does.
- `home/nixvim/custom/mdmath.nix`: Use filetypes condition from setup.
- `justfile`: Format the `justfile`.
- `system/base/nix.nix`: Add missing keys to `trusted-public-keys`.
- `system/base/nix.nix`: Configure `speedFactor` and `maxJobs`.
- `home/agents/instructions.nix`: Find the proper names for "math block" and "inline math".
- `home/gui/default.nix`: Parametrize the configuration.
- `home/agents/sandbox.nix`: Move sandbox settings to specific agents.
- `home/agents/default.nix`: Rename the file.
- `home/agents/commands.nix`: Investigate why `!lines` gets executed for Claude.
- `hax/common.nix`: Rename the file.
- `hax/common.nix`: Decide whether to move a code block.
- `hax/hosts.nix`: Deduplicate keypath.
- `home/lang/default.nix`: Categorize miscellaneous language settings.
- `home/nixvim/ft.nix`: Unmap `gO`.
- `home/agents/frontends/default.nix`: Replace hardcoded `CLAUDE.md` path.
- `home/nixvim/lang/haskell.nix`: Add haskell-tools.
- `home/nixvim/base.vim`: Review and remove unnecessary `!` where possible.
- `home/nixvim/lang/markdown.nix`: Unmap `gO`.
- `home/tui/bin/diriger.sh`: Add project and feature to the tmux session name.
- `home/tui/bin/diriger.sh`: Check if command escaping is needed.
- `home/tui/bin/diriger.sh`: Factor out hardcoded numbers.
- `home/tui/bin/diriger.sh`: Fix ugly output with `dry-run`.
- `home/tui/bin/diriger.sh`: Add usage instructions.
- `home/gui/desktop/clipboard.nix`: Check if all fields in the config are required.
- `home/default.nix`: Research what `programs.home-manager.enable = true;` does.
- `home/tui/bash/default.nix`: Verify and move a code block.
- `home/tui/bash/default.nix`: Move XDG shims to the main bash file.
- `home/tui/bash/default.nix`: Rename `lib.excludeShellChecks.numbers`.
- `home/nixvim/lang/markup/json.nix`: Check if the configuration is required.
- `home/tui/git.nix`: Decide whether to keep or delete an unused feature.
- `home/gui/desktop/swaylock.nix`: Investigate the PAM configuration comment.
- `home/tui/bash/git.sh`: Reconsider stderr/stdout usage.
- `home/tui/bash/git.sh`: Refactor variables to be more `local`/`readonly`.
- `home/tui/bash/git.sh`: Check the `awk` script that was generated by GPT.

## TBD (To Be Determined)

- `common/overlays.nix`: "pure vibes" - unclear what this means.
- `justfile`: "just inputs" - unclear what this means.
- `home/gui/packages.nix`: "apply" - unclear what to apply.
- `home/tui/packages.nix`: "miscellaneous unfiled TODO" - requires clarification.
- `home/agents/frontends/avante.nix`: "mcphub" - unclear what this means.
- `home/nixvim/lang/markdown.nix`: "more?" - unclear what else is needed.
- `home/nixvim/misc.nix`: No description provided.
- `home/tui/bin/default.nix`: "read builders, move and read public" - unclear.
- `home/nixvim/ide/lsp.nix`: "autoActivate = false;" - unclear what the task is.
