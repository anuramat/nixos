# AGENTS.md

NOTE: CLAUDE.md is symlink to AGENTS.md

This is the user's NixOS and Home Manager flake at `/etc/nixos`. It configures
NixOS hosts, Home Manager profiles, a nixvim setup, local overlays, ragenix
secrets, desktop services, AI-agent wrappers, and some server/web services.

## Agent Workflow

- Keep changes narrow and rooted in the actual checkout. If the user names one
  host, module, file, wrapper, or command, avoid adjacent cleanup unless it is
  required for the requested change.
- Before editing, identify acceptance criteria and include the verification
  step in your plan. For a failing command, the same command succeeding is an
  acceptance criterion.
- Prefer focused Nix evals or parse checks while debugging. Do not rebuild the
  whole system unless the user asks for that level of verification.
- Use `nh search PACKAGE` for nixpkgs lookup and `nixos-option OPTION` for
  NixOS option exploration. Do not use `nix search`.
- If a needed tool is missing, prefer `nix run nixpkgs#PACKAGE -- ARGS`.
- If asked to notify the user, pipe a message to `tgfy`; attachments are
  optional: `echo 'done' | tgfy file.png`.
- Commit subjects, when requested, use `SCOPE: SHORT_DESCRIPTION`, not
  conventional-commit `type(scope): ...`.

Useful repo commands:

- `nix develop`: enter the dev shell with `just`, `nh`, `nixfmt`,
  `shellcheck`, `yamllint`, and Lua checking tools.
- `just format`: run `nix fmt` through treefmt.
- `just lint`: run statix, deadnix, Nix parsing, luacheck, shellcheck, and
  yamllint.
- `just check`: run `nix flake check`; the `checks` output evaluates every
  host's toplevel (firing all assertions) without building it.
- `just check-nixos HOST`: dry-run build the NixOS toplevel for a host.
- `just check-hm USER`: dry-run build a Home Manager activation package.
- `just nixos-local build --flake .#HOST`: build a host without remote
  builders when full host validation is wanted.

## Flake Shape

`flake.nix` holds literal inputs and imports `./outputs.nix` (a flake-parts
composition root) for outputs. There is no `inputs.nix` or generated-flake
pipeline.

`outputs.nix` turns direct directory children into public flake outputs, so
adding, removing, or renaming a direct child is an API change for this flake:

- `nixosConfigurations`: `nixos-configurations/`. Each host directory has a
  `default.nix`, generated `hardware-configuration.nix`, and public keys under
  `keys/`.
- `homeConfigurations`: `home-configurations/` (standalone Home Manager).
- `nixosModules`: `nixos-modules/`.
- `homeModules`: `home-modules/`.
- `nixvimModules`: `nixvim-modules/`. The editor is nixvim-based, not a
  hand-written `init.lua`; the real root is `nixvim-modules/default/default.nix`,
  activated via `inputs.nixvim.homeModules.nixvim ->
  home-modules/heavy/editor.nix -> self.nixvimModules.default`.
- `sharedModules`: `shared-modules/`, usable from both NixOS and standalone
  Home Manager.
- `overlays`: `overlays/`.

`outputs.nix` also exposes:

- `hosts`: a hand-written static registry of `{ system, builder }` per host.
  Cross-host facts come from this registry, not from evaluating sibling
  configurations. Adding a host (or changing its system/builder status)
  requires updating the registry. `nixos-modules/default/hosts.nix` asserts
  the registry against the host's actual config, and the per-host
  `checks.SYSTEM.host-NAME` outputs evaluate every host's toplevel, so
  `nix flake check` catches drift on all hosts. Host changes can still affect
  secrets, SSH, substituters, and remote-build behavior on every other host.
- `keys`: per-host key material discovered from `nixos-configurations/*/keys/`
  (client key files and strings, `known_hosts` file path and parsed keys,
  cache key). Single source of truth for key discovery, consumed by
  `nixos-modules/default/hosts.nix` and `secrets/secrets.nix`.

Per-system outputs: `packages.neovim` (nixvim-built Neovim from
`self.nixvimModules.default`), `devShells.default`, and the flake-parts
modules under `parts/` (treefmt, pre-commit, nix-topology).

The repo uses the experimental Nix pipe operator (`|>`) throughout modules and
helper code. Raw parse/eval commands may need the `pipe-operators`
experimental feature; run inside the dev shell or pass it explicitly.

## Layering

- `nixos-modules/default/`: baseline imported by every NixOS host (agenix,
  Home Manager, user/network/nix/web/llama plumbing).
  `nixos-modules/local/`: workstation layer on top of it.
- `home-modules/` layers: `default` (base CLI environment), `linux`
  (Linux-only CLI), `heavy` (editor, toolchains, GUI-independent extras),
  `heavy/gui` (graphical apps), `heavy-linux` (Niri desktop and AI agents).
- Hosts: `anuramat-root` (server-like QEMU guest; nginx, ACME, `ctrl.sn`,
  wastebin), `anuramat-t480` (ThinkPad T480 laptop), `anuramat-f12`
  (Framework 12 laptop), `anuramat-bgm5` (AMD Strix Halo workstation; build
  server, ROCm, llama, Immich). Per-host details live in
  `nixos-configurations/*/default.nix`.

## Secrets and Keys

- Encrypted secrets live as `secrets/*.age`.
- `shared-modules/age.nix` automatically creates `age.secrets` entries for
  every `.age` file under `secrets/`; on NixOS it sets the owner to the primary
  user.
- `secrets/secrets.nix` computes recipients from the flake `keys` output:
  client keys plus `known_hosts` keys of every host.
- Host public keys live under `nixos-configurations/$HOST/keys/`: client
  `*.pub` keys, `known_hosts`, and `cache.pem.pub`.
- `just nixos-pre` refreshes the current host's `known_hosts`, public client
  keys, and binary-cache public key before rebuild-oriented commands.

## Surprising Or Complex Parts

- `nixos-modules/builder.nix` asserts `!config.nix.distributedBuilds`; a builder
  host is modeled as a build server, not as a distributed-build client.
- `overlays/default.nix` mixes stable inputs, unstable package imports,
  personal flake packages, impure `npx`/`uv tool run` wrappers, and a Proton
  Bridge source override. Since the default NixOS module applies it globally,
  overlay edits can affect system packages, Home Manager, and nixvim.
- Home Manager activation helpers in `home-modules/default/lib.nix` mutate JSON
  and YAML files in place with jq/yq and log diffs under XDG state. Some configs
  are not simple `xdg.configFile` declarations.
- `services.pss` is a custom Home Manager module replacing the normal
  pass-secret-service module with a Rust package built from the flake input. It
  also ships `pss-migrate` for migration.
- Agent commands are generated from Nix. `home-modules/heavy-linux/agents`
  builds Codex/Claude instruction files, skill/prompt files, TOML/JSON configs,
  and bubblewrap wrappers.
- The Codex wrappers intentionally pass dangerous approval/sandbox flags to the
  wrapped tool, while the wrapper itself uses bubblewrap with selected read-only
  and read-write binds. Distinguish Codex's own sandbox from this outer wrapper.
- `codex-remote` has a gated systemd user service, but the package is installed
  by the Codex frontend module. Service enablement and package exposure are not
  the same thing here.
- Niri starts from a bash profile autostart script and a user systemd service,
  not from a display manager. `wayland.systemd.target` is set to `niri.service`
  because the generic graphical session target starts some services too early.
- Waybar's niri-windows plugin is built from the `waybar-niri-windows` flake
  input; bumping the input may also require updating `vendorHash` in
  `home-modules/heavy-linux/desktop/niri/bar.nix`.
- The desktop uses keyd home-row `lettermod` remaps plus host-specific keyboard
  IDs. Keyboard behavior is split between shared remaps and per-host IDs.
- bgm5 uses only selected attributes from the `nix-strix-halo` overlay instead
  of importing the whole upstream default overlay. Its quiet fan/EC behavior is
  in host-local `power.nix`.
- `shared-modules/stylix.nix` plus `nixos-modules/local/rice.nix` make theming a
  cross-cutting concern. A theme change can affect system boot visuals, desktop
  apps, terminals, and nixvim.
