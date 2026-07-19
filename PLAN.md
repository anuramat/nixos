# Module maintainability plan

Scope: `nixos-modules/`, `home-modules/`, and the module/configuration export
machinery in `outputs.nix`. Preserve existing host behavior except where a
change is stated explicitly below.

Verified baseline:

- `homeConfigurations` currently contains only `".gitignore"`; evaluating it
  as a Home Manager configuration fails because `homeSystems` has no matching
  entry.
- `services.nix-serve.enable` is true on all four NixOS hosts, while only
  `anuramat-bgm5` imports `nixosModules.builder`.
- `anuramat-root` receives all fifteen groups from
  `nixos-modules/default/user.nix` and has
  `services.getty.autologin = "anuramat"` despite not importing
  `nixosModules.local`.
- The four host configurations evaluate far enough to inspect the values
  above. A full `nix flake check` was not completed during the review: it
  timed out after 120 seconds while fetching during evaluation of
  `anuramat-bgm5`.

## 1. Export only intended flake entries

`mapModuleDir` in `outputs.nix` treats every directory entry as importable.
This makes unrelated files part of the flake API; at present,
`home-configurations/.gitignore` becomes a broken configuration.

Change:

- Use separate discovery helpers for `.nix` module files and configuration
  directories.
- Apply the former to `nixos-modules`, `home-modules`, `nixvim-modules`,
  `shared-modules`, and `overlays` as appropriate, and the latter to
  `nixos-configurations` and `home-configurations`.
- Do not silently accept unexpected entry types.

Completion checks:

- `lib.attrNames inputs.self.homeConfigurations` contains no incidental files.
- Every exported module/configuration name corresponds to an intended source
  entry.
- Adding a non-Nix file beside modules does not add a flake output.

## 2. Make the builder module own the builder service

`nixos-modules/builder.nix` defines the builder account and SSH access, but
`nixos-modules/default/nix.nix` enables `nix-serve` on every host. The role is
therefore split between a specialized module and the universal base module.

Change:

- Move the `nix-serve` configuration into `nixos-modules/builder.nix`.
- Keep client-side substituter and `buildMachines` configuration in the base
  Nix module.
- Keep the existing assertion that a builder does not also use distributed
  builds unless that policy is deliberately changed separately.

Completion checks:

- `services.nix-serve.enable` is true on `anuramat-bgm5` and false on the three
  non-builder hosts.
- The non-builder hosts still configure `anuramat-bgm5` as their remote
  builder.
- Builder SSH authorization and host-registry assertions remain unchanged.

## 3. Move user capabilities to the modules that require them

`nixos-modules/default/user.nix` currently owns identity, desktop/peripheral
groups, OpenRGB access, and Getty behavior. Consequently server and desktop
hosts receive the same capability set.

Change:

- Leave basic account creation, identity, SSH keys, and the universally needed
  groups in `default/user.nix`.
- Assign `nginx`, Syncthing, printing/scanning, Android, serial, network,
  peripheral, and similar groups beside the services/programs that require
  them.
- Move Getty autologin and OpenRGB user access to the relevant local/desktop or
  peripheral modules.
- While doing this, split `nixos-modules/local/default.nix` only where the new
  ownership boundary requires it; do not create files solely to reduce line
  count.

Completion checks:

- `anuramat-root` has no desktop/peripheral groups or Getty autologin unless a
  server service explicitly needs them.
- The three local graphical hosts retain the capabilities needed by their
  enabled services and hardware.
- Existing login, printing, networking, Syncthing, Android, and peripheral
  behavior is preserved on hosts that use it.

## 4. Evaluate standalone Home Manager paths

The deployed NixOS hosts exercise Home Manager through `osConfig`, but
`home-modules/standalone.nix`, `home-modules/darwin.nix`, and branches for
`osConfig == null` have no valid configuration exercising them.

Change:

- After fixing export discovery, add explicit evaluation checks for the
  supported standalone module combinations on Linux and Darwin.
- If a combination is not actually supported, remove its public module rather
  than leaving an untested interface.

Completion checks:

- At least one check evaluates the intended `osConfig == null` path.
- Darwin-specific imports are evaluated on `aarch64-darwin` if Darwin remains
  supported.
- The four existing NixOS/Home Manager integrations continue to evaluate.

## 5. Scope and test the Nixvim option extension

`home-modules/default/options.nix` imports Nixvim and redeclares
`programs.nixvim` solely to pass `inputs` and `osConfig` into nested modules.
It is marked `SLOP`, but is imported by the base Home Manager module even
though only `home-modules/heavy/editor.nix` configures Nixvim.

Change:

- Move the Nixvim import and option extension to the smallest module layer that
  needs it, normally `home-modules/heavy/editor.nix` or a sibling helper.
- Add a focused evaluation test proving that nested Nixvim modules receive both
  `inputs` and, under NixOS, `osConfig`.

Completion checks:

- The base Home Manager module can evaluate without importing Nixvim.
- The heavy editor configuration still builds the same Nixvim package.
- Both standalone and NixOS-backed argument-passing tests succeed.

## 6. Remove the single-use llama-cpp abstraction

`nixos-modules/default/llama.nix` adds a large typed wrapper around
`services.llama-cpp` and converts it back into CLI flags. Its only consumer is
`nixos-configurations/anuramat-bgm5/llama.nix`, and the custom options occupy
the upstream service namespace.

Change:

- Express the selected model and llama-cpp flags directly in the bgm5
  configuration.
- Preserve the `LLAMA_CACHE` value and the package exposed in
  `environment.systemPackages`.
- If reuse is expected imminently, keep a helper under a repository-owned
  namespace instead of extending `services.llama-cpp`.

Completion checks:

- The evaluated model path, flags, host, port, and package match the current
  bgm5 configuration.
- Enabling the service produces the same systemd service command.
- No `modelDir` or `modelWrapped` options remain under `services.llama-cpp`.

## 7. Simplify identity ownership

`nixos-modules/default/user.nix` derives the account name and email from the
Home Manager Git configuration, while selecting a Home Manager module by the
account username. The email option is currently unused outside its definition.

Change:

- Remove the unused `userConfig.email` option.
- Give the remaining identity fields one explicit source of truth, then feed
  both NixOS account metadata and Home Manager Git configuration from it.
- Keep the username-to-module naming convention only if it remains useful; do
  not add a generic module-selection abstraction for the single current user.

Completion checks:

- The NixOS account description and Git name/email remain unchanged.
- No NixOS option depends on an unrelated Home Manager program subtree.

## Final validation

After each item, run the narrow evaluation checks listed above. After all
items:

1. Run `nix flake check` to completion.
2. Evaluate every `nixosConfigurations` toplevel.
3. Evaluate the supported standalone Home Manager configurations.
4. Confirm that only intended flake outputs are exported.
