# Maintainability Problems

## 1. Hardcoded Personal Data
- Username "anuramat" hardcoded in `outputs.nix:41` and elsewhere
- Personal paths (`~/notes`, `~/books`) scattered throughout codebase
- Timezone hardcoded in `nixos-modules/anuramat.nix`
- Makes repository impossible to fork/reuse without extensive modifications

## 2. Dual Entrypoint Architecture
- Two separate entrypoints for home-manager (NixOS module vs standalone)
- Two separate entrypoints for nixvim (NixOS module vs standalone)
- Requires duplicating specialArgs and modules in both places
- Increases maintenance burden and risk of configuration drift

## 3. Circular and Parent Directory Dependencies
- `../` imports in `/secrets` directory (`secrets.nix:5,8`)
- Tests importing from parent directories
- Violates module isolation principles
- Makes modules less portable and harder to test independently

## 4. Magic Behaviors and Implicit Assumptions
- Auto-discovery of hosts requires directory name to match hostname exactly
- SSH keys stored in repo under rigid directory structure
- Builder setup requires manual SSH config due to Nix bug (#3423)
- Many undocumented assumptions about file locations and naming

## 5. Extensive Technical Debt
- 139 TODO/BUG/FIXME/HACK markers across 72 files
- Critical workarounds like builder SSH configuration
- Incomplete implementations scattered throughout
- No clear prioritization or tracking of issues

## 6. Insufficient Test Coverage
- Only 6 test files for entire codebase
- Tests only cover `hax/` utility functions
- No integration tests for NixOS/home-manager configurations
- No tests for critical functionality like host discovery

## 7. Experimental Feature Dependency
- Heavy reliance on Nix pipe operators (`|>`)
- Requires special flags for all operations
- Incompatible with standard Nix tooling (statix, deadnix)
- Limits collaboration and tool ecosystem usage

## 8. Tight Module Coupling
- Modules heavily depend on specific directory structure
- Hard dependencies on `hax` library throughout
- Difficult to extract or reuse individual modules
- No clear separation between core and optional functionality