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
