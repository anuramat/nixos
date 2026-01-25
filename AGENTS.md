# AGENTS — repo helper for agentic coding

## Commands

- Format: `just format` or `nix fmt`
- Lint: `just lint` (runs `luacheck`, `shellcheck`, `yamllint`)
- Build flake: `just flake`
- Run all unit tests: `just test` (auto-detects system arch)
- Run single test: get arch with `nix eval --raw .#nixosConfigurations.$(hostname).config.nixpkgs.hostPlatform.system` then run `nix-unit --flake .#tests.systems.<arch> <testName>`
- Snapshot / matrix: `just test-snapshot`, `just test-matrix`

## Repo layout & modules

- Top-level: `flake.nix`, `outputs.nix`, `justfile`, `README.md`.
- `nixos-configurations/`: host-specific NixOS configs.
- `home-configurations/`, `home-modules/`: home-manager configs and modules.
- `nixos-modules/`, `shared-modules/`, `overlays/`, `parts/`: reusable modules and flakes parts.
- `tests/`: nix-unit tests (attribute-sets) and integration scripts under `tests/integration/`.

## Style (short)

- Nix: run `nix fmt`; prefer concise expressions, explicit `lib` imports, camelCase for functions/attrs, and clear `throw` messages.
- Lua: format with `stylua` (see `.stylua.toml`); lint with `luacheck --globals=vim`.
- Shell: `set -euo pipefail`; lint with `shellcheck`.
- Tests: put deterministic, self-contained attr-sets under `tests/*`; name in camelCase.
- Git: commit small, focused changes; follow atomic commits for each logical change.

## Updating tool packages (e.g., codex)

- Touch `overlays/default/misc.nix` only for the target derivation; bump `version` and reuse the existing URL template.
- Get latest version:
  - npm packages: `curl -s https://registry.npmjs.org/@anthropic-ai/claude-code | grep -o '"latest":"[^"]*"' | cut -d'"' -f4`
  - GitHub releases: `curl -s https://api.github.com/repos/openai/codex/releases/latest | jq -r '.tag_name'`
- Determine the required hash by running `just build pkgname` (with the hash intentionally left empty); copy the hash that appears in the resulting failure message.
- Validate the overlay in isolation with `nix build --impure --expr 'let flake = builtins.getFlake (toString ./.) ; pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; overlays = [ flake.outputs.overlays.default ]; }; in pkgs.codex'`.
- Commit just the overlay change plus the hash bump once the build succeeds.
