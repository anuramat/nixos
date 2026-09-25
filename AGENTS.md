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
- `nix fmt`: format through treefmt.
- `just lint`: run statix, deadnix, Nix parsing, luacheck, shellcheck, and
  yamllint.
- `nix flake check`: the `checks` output evaluates every host's toplevel
  (firing all assertions) without building it.
- `just nixos [COMMAND] [FLAGS]`: `nixos-rebuild COMMAND` (default `switch`)
  on the current host; `just nixos-local ...` does the same without remote
  builders or `http:` substituters, `just nixos-offline ...` with `--offline`.
  E.g. `just nixos-local build --flake .#HOST` builds a host locally when full
  host validation is wanted.
- `just build PKG` / `just run PKG ARGS`: build/run a package from the current
  host's `pkgs` (overlays applied).
- `just update-agents`: bump the AI agent flake inputs.

## Flake Shape

`flake.nix` holds literal inputs and imports `./outputs.nix` (a flake-parts
composition root) for outputs. There is no `inputs.nix` or generated-flake
pipeline.

`outputs.nix` turns direct directory children into public flake outputs, so
adding, removing, or renaming a direct child is an API change for this flake:

- `nixosConfigurations`: `nixos-configurations/`. Each host directory has a
  `default.nix`, generated `hardware-configuration.nix`, and public keys under
  `keys/`.
- `homeConfigurations`: `home-configurations/` (standalone Home Manager). Each
  entry needs a matching `homeSystems` entry in `outputs.nix`, which also drives
  the `checks.SYSTEM.home-NAME` outputs.
- `nixosModules`: `nixos-modules/`.
- `homeModules`: `home-modules/`.
- `nixvimModules`: `nixvim-modules/`. The editor is nixvim-based, not a
  hand-written `init.lua`. It mirrors the Home Manager layers: `base` (minimal
  editor) and `heavy` (everything else), which does not import `base` and is
  only meaningful on top of it. `home-modules/base/editor.nix` imports
  `inputs.nixvim.homeModules.nixvim` and enables nixvim with
  `self.nixvimModules.base` on every configuration;
  `home-modules/heavy/editor.nix` adds `self.nixvimModules.heavy`.
- `sharedModules`: `shared-modules/`, usable from both NixOS and standalone
  Home Manager.
- `overlays`: `overlays/`.

`outputs.nix` also exposes:

- `hosts`: a hand-written static registry of `{ system, builder, agent }` per
  host, plus a `description` on agent hosts (rendered into the agents' ssh
  instructions by `home-modules/heavy-linux/agents/instructions.nix`) and an
  optional ssh `alias` (every host gets an ssh config entry in
  `home-modules/base/default.nix`, under its alias if it has one).
  Cross-host facts come from this registry, not from evaluating sibling
  configurations. Adding a host (or changing its system/builder/agent status)
  requires updating the registry. The `builder` and `agent` flags enable
  `nixos-modules/base/{builder,agent}.nix` on that host; `hosts.nix` asserts
  the registry's names and systems against the configurations, and the per-host
  `checks.SYSTEM.host-NAME` outputs evaluate every host's toplevel, so
  `nix flake check` catches drift on all hosts. Host changes can still affect
  secrets, SSH, substituters, and remote-build behavior on every other host.
- `user`: the primary account's identity (`username`, `name`, `email`,
  `timeZone`, `locale`, `location`). The only place these are written; every
  consumer reads `inputs.self.user` directly, with no intervening NixOS option.
  Multiple users are an explicit non-goal, so there is deliberately nothing to
  override per host. Consumed by
  `nixos-modules/base/{user,net,nix,web,external_keys,default}.nix`,
  `nixos-modules/local/{default,peripherals}.nix`, `shared-modules/age.nix`
  (secret owner), `home-modules/base/git/` (Git identity),
  `home-modules/heavy-linux/desktop/niri/noctalia.nix` (weather location),
  `home-configurations/*` (username and home directory), and
  `nixos-configurations/anuramat-root/web/` (ACME contact). Per-host Home
  Manager overrides must be keyed
  `home-manager.users.${inputs.self.user.username}`, never a literal username,
  or renaming the account silently produces an entry for a user that has no
  modules imported.
- `llama`: the designated LLM inference endpoint (host and port), consumed by
  `nixos-configurations/anuramat-bgm5/llama.nix` and `home-modules/base/hosts.nix`.
- `keys`: per-host key material discovered from `nixos-configurations/*/keys/`
  (client key files and strings, `known_hosts` file path and parsed keys,
  cache key). Single source of truth for key discovery, consumed by
  `nixos-modules/base/hosts.nix` and `secrets/secrets.nix`.

Per-system outputs: `packages.neovim` and `packages.neovim-minimal`
(nixvim-built Neovim from `self.nixvimModules.{base,heavy}` and
`self.nixvimModules.base`), `devShells.default`, and the flake-parts
modules under `parts/` (treefmt, pre-commit, nix-topology).

The repo uses the experimental Nix pipe operator (`|>`) throughout modules and
helper code. Raw parse/eval commands may need the `pipe-operators`
experimental feature; run inside the dev shell or pass it explicitly.

## Layering

- `nixos-modules/base/`: baseline imported by every NixOS host (agenix,
  Home Manager, user/network/nix/web plumbing, plus `rocm.nix`/`cuda.nix`,
  which are gated on `nixpkgs.config.rocmSupport`/`cudaSupport`).
  `nixos-modules/local/`: workstation layer on top of it.
  `nixos-modules/laptop/`: power management and keyd remaps, imported by
  t480 and f12 only.
- `home-modules/` layers: `base` (base CLI environment, cross-platform),
  `linux` (Linux-only CLI), `local` (physical machines, cross-platform),
  `local-linux` (Linux hardware tools), `heavy` (editor, toolchains,
  media/office CLI, and cross-platform graphical apps in `heavy/gui.nix`),
  `heavy-linux` (Niri desktop, AI agents, and Linux-only graphical apps in
  `heavy-linux/gui`). `local`, `local-linux`, `heavy` and `heavy-linux` are
  always imported together on NixOS, so Linux-only additions belong in the
  `-linux` layers; keeping `local` and `heavy` Darwin-clean is what makes the
  `anuramat-darwin` home configuration evaluate.
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
- The private `nixos-pre` recipe, run before every `just nixos*` rebuild,
  refreshes the current host's `known_hosts`, public client keys, and
  binary-cache public key.

## Surprising Or Complex Parts

- `nixos-modules/base/builder.nix`, on hosts flagged `builder` in the registry,
  asserts `!config.nix.distributedBuilds`; a builder host is modeled as a build
  server, not as a distributed-build client.
- `nixos-modules/base/agent.nix`, on hosts flagged `agent` in the registry
  (bgm5), accepts ssh from sandboxed agents on other hosts as
  `config.lib.hosts.agentUsername`. The bwrap sandbox binds
  `secrets/agent.age` read-only and replaces `/etc/ssh` with its own
  `ssh_config` (that key only, plus every host's `known_hosts` from the `keys`
  output). It has to be the top-level system file: inside the sandbox root is
  unmapped, so store-owned files show as nobody's, and ssh rejects a user
  config or an `Include` owned like that but not the system file itself. sshd
  runs every session of that user through a logging
  `ForceCommand` (`journalctl -t agent-ssh`) with forwarding disabled. The
  public half lives inline in the module, not under `keys/`, because every
  `*.pub` there is authorized for the primary user and `builder`.
- `overlays/default.nix` mixes stable inputs, unstable package imports,
  personal flake packages, impure `npx`/`uv tool run` wrappers, and a Proton
  Bridge source override. Since the base NixOS module applies it globally,
  overlay edits can affect system packages, Home Manager, and nixvim.
- Home Manager activation helpers in `home-modules/base/lib.nix` mutate JSON
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
  input; bumping it may also require updating the hand-pinned `vendorHash` in
  `overlays/default.nix`. The package is built by `nix flake check` so a stale
  hash fails there, not at rebuild time.
- keyd home-row `lettermod` remaps come from `nixos-modules/laptop/keyboard.nix`
  and apply only to the keyboard IDs each laptop host lists in
  `services.keyd.keyboards.main.ids`; the `local` layer alone (bgm5) has no
  keyd, so setting IDs there is dead config.
- bgm5 uses only selected attributes from the `nix-strix-halo` overlay instead
  of importing the whole upstream default overlay. Its quiet fan/EC behavior is
  in host-local `power.nix`.
- `shared-modules/stylix.nix` plus `nixos-modules/local/rice.nix` make theming a
  cross-cutting concern. A theme change can affect system boot visuals, desktop
  apps, terminals, and nixvim.
