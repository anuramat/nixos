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
- Packages: "add a package" means adding it to the default overlay only; do not wire it into NixOS/home-manager configs or flake outputs unless asked.

## Typical workflows

### When user asks to update a package

1. find the existing override in the default overlay; if it's not there, create
   a new override
2. in the override, set the version to the requested one. if the user didn't
   specify a version, find the latest version online -- search online for the
   github repository, and get the latest stable version from the releases.
   set the hash to empty string.
3. fetch the archive with `nix-prefetch-url --type sha256 <download_url>` (or `nix store prefetch-file`),
   then convert its output to SRI via `nix hash to-sri --type sha256 <output>`
4. replace the empty hash with the converted value
5. run `just build <package_name>` once to verify everything works

If the final step causes an error because of vendor/cargo hash mismatch, fix it
and build again. If any other error occurs, stop and explain the problem to the
user.
