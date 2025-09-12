# AGENTS — repo helper for agentic coding

## Commands
- Format: `just format` or `nix fmt`
- Lint: `just lint` (runs `luacheck`, `shellcheck`, `yamllint`)
- Build flake: `just flake`
- Run all unit tests: `just test` (auto-detects system arch)
- Run single test: get arch with `nix eval --raw .#nixosConfigurations.$(hostname).config.nixpkgs.hostPlatform.system` then run `nix-unit --flake .#tests.systems.<arch> <testName>` (replace `<testName>` with the attribute name)
- Snapshot / matrix: `just test-snapshot`, `just test-matrix`

## Style (short)
- Nix: run `nix fmt`; prefer concise expressions, explicit `lib` imports, camelCase for functions/attrs, and clear `throw` messages for errors.
- Lua: format with `stylua` (see `.stylua.toml`); lint with `luacheck --globals=vim`; keep code minimal.
- Shell: use `set -euo pipefail`; lint with `shellcheck` (justfile does this).
- Tests: tests are attribute-sets under `tests/*`; name tests in camelCase, use deterministic inputs, and encode expected errors explicitly.
- Commits: keep changes small and focused; commit after each atomic unit of work.

No `.cursor`/`.cursorrules` or `.github/copilot-instructions.md` were found; follow the rules above.