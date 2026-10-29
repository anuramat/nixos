# AGENTS.md

NOTE: CLAUDE.md is symlink to AGENTS.md

This is the user's NixOS and Home Manager flake at `/etc/nixos`. It configures
NixOS hosts, Home Manager profiles, a nixvim setup, local overlays, ragenix
secrets, desktop services, AI-agent wrappers, and some server/web services.

## Agent Workflow

- Keep changes narrow and rooted in the actual checkout. If the user names one
  host, module, file, wrapper, or command, avoid adjacent cleanup unless it is
  required for the requested change.
- Prefer focused Nix evals or parse checks while debugging. Do not rebuild the
  whole system unless the user asks for that level of verification.
- Use `nixos-option OPTION` for NixOS option exploration.

Useful repo commands:

- `nix develop`: enter the dev shell with `just`, `nh`, `nixfmt`, `statix`,
  `deadnix`, `shellcheck`, and `yamllint`.
- `nix fmt`: format through treefmt.
- `just lint`: run statix, deadnix, Nix parsing, shellcheck, and yamllint.
- `nix flake check`: the `checks` output evaluates every host's toplevel
  (firing all assertions) without building it.
- `just nixos [COMMAND] [FLAGS]`: `nixos-rebuild COMMAND` (default `switch`)
  on the current host; `just nixos-local ...` does the same without remote
  builders or `http:` substituters, `just nixos-offline ...` with `--offline`.
- `just build PKG` / `just run PKG ARGS`: build/run a package from the current
  host's `pkgs` (overlays applied).
- `just update-agents`: bump the AI agent flake inputs.

The repo uses the experimental Nix pipe operator (`|>`); raw parse/eval
commands may need the `pipe-operators` experimental feature.

## Flake Shape

`flake.nix` holds literal inputs and imports `./outputs.nix` (a flake-parts
composition root). `outputs.nix` turns direct directory children into public
flake outputs, so adding, removing, or renaming a direct child is an API
change: `nixos-configurations/`, `home-configurations/` (each entry also needs
a `homeSystems` entry in `outputs.nix`), `nixos-modules/`, `home-modules/`,
`nixvim-modules/`, `shared-modules/` (usable from both NixOS and standalone
Home Manager), `overlays/`.

The editor is nixvim-based, not a hand-written `init.lua`. `nixvim-modules`
mirrors the Home Manager layers: `base` (minimal editor) and `heavy`, which is
only meaningful on top of `base`.

`outputs.nix` also exposes:

- `hosts`: a hand-written registry of `{ system, builder, agent, local, alias }`
  plus a required `description` per host. Cross-host facts come from this
  registry, never from evaluating sibling configurations, so adding a host or
  changing its flags means updating it. `builder` and `agent` enable
  `nixos-modules/base/{builder,agent}.nix`; `local` (physical machines)
  imports `nixos-modules/local/` from `outputs.nix`, not from the host.
  `hosts.nix` asserts the registry against the configurations. Host changes
  can affect secrets, SSH, substituters, and remote builds on every other host.
- `consts`: constants shared by NixOS, Home Manager and nixvim modules, read
  directly as `inputs.self.consts` (grep for consumers). Multiple users are a
  non-goal. Per-host Home Manager overrides must be keyed
  `home-manager.users.${inputs.self.consts.user.username}`, never a literal
  username.
- `keys`: per-host key material discovered from `nixos-configurations/*/keys/`;
  the single source of truth for key discovery.

## Layering

- `nixos-modules/base/`: every NixOS host. `nixos-modules/local/`: hosts
  flagged `local`. `nixos-modules/laptop/`: imported by laptop hosts.
- `home-modules/` layers: `base` (CLI, cross-platform), `linux` (Linux-only
  CLI), `local` (physical machines, cross-platform), `local-linux`, `heavy`
  (editor, toolchains, cross-platform GUI apps), `heavy-linux` (Niri desktop,
  AI agents, Linux-only GUI apps). `local`, `local-linux`, `heavy` and
  `heavy-linux` are always imported together on NixOS, so Linux-only additions
  belong in the `-linux` layers: keeping `local` and `heavy` Darwin-clean is
  what makes `anuramat-darwin` evaluate. Opt-in feature modules (`pss`, `todo`)
  are imported by the layer that enables them.
- Per-host details live in `nixos-configurations/*/default.nix`.

## Secrets and Keys

- `shared-modules/age.nix` creates an `age.secrets` entry for every
  `secrets/*.age` file; `secrets/secrets.nix` computes recipients from the
  `keys` output.
- The private `nixos-pre` recipe, run before every `just nixos*` rebuild,
  refreshes the current host's public keys under `keys/`.

## Surprising Or Complex Parts

- A host flagged `builder` is a build server, never a distributed-build client
  (`nix.distributedBuilds` in `nixos-modules/base/nix.nix`).
- `nixos-modules/base/agent.nix`, on hosts flagged `agent`, accepts ssh from
  sandboxed agents on other hosts as `consts.agent.username`. The bwrap
  sandbox binds `secrets/agent.age` read-only and replaces `/etc/ssh` with its
  own `ssh_config`. It has to be the top-level system file: inside the sandbox
  root is unmapped, so store-owned files show as nobody's, and ssh rejects a
  user config or an `Include` owned like that but not the system file itself.
  sshd runs every session of that user through a logging `ForceCommand`
  (`journalctl -t agent-ssh`) with forwarding disabled. The public half lives
  inline in the module, not under `keys/`, because every `*.pub` there is
  authorized for the primary user and `builder`.
- `overlays/default.nix` is applied globally by the base NixOS module, so
  overlay edits can affect system packages, Home Manager, and nixvim.
- Home Manager activation helpers in `home-modules/base/lib.nix` mutate JSON
  and YAML files in place, so some configs are not simple `xdg.configFile`
  declarations.
- Agent commands, instruction files, configs and bubblewrap wrappers are
  generated from Nix in `home-modules/heavy-linux/agents`. Commands that reach
  out of the sandbox (`hostrun`, `uc3ctl`) are relays: `agents.relays.NAME =
  HANDLER` (`agents/relay/`) creates a socket-activated
  `$XDG_RUNTIME_DIR/NAME.sock`, binds it into every sandbox, and logs each
  call to `journalctl --user -u 'NAME@*'`.
- The Codex wrappers intentionally pass dangerous approval/sandbox flags to the
  wrapped tool, while the wrapper itself uses bubblewrap. Distinguish Codex's
  own sandbox from this outer wrapper.
- Niri starts from a bash profile autostart script and a user systemd service,
  not from a display manager.
- Noctalia GUI changes land in `$XDG_STATE_HOME/noctalia/settings.toml`; to
  save them to the config, follow the procedure at the top of
  `home-modules/heavy-linux/desktop/noctalia/default.nix`.
- keyd `lettermod` remaps (`nixos-modules/laptop/keyboard.nix`) apply only to
  the keyboard IDs each laptop host lists in `services.keyd.keyboards.main.ids`.
- Theming (`shared-modules/stylix.nix`, `nixos-modules/local/rice.nix`) is
  cross-cutting: a theme change can affect boot visuals, desktop apps,
  terminals, and nixvim.
