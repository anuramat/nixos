# Repository Guide

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

- `nix develop`: enter the dev shell with `just`, `nh`, `nixfmt`, `nix-unit`,
  `shellcheck`, `yamllint`, and Lua checking tools.
- `just format`: run `nix fmt` through treefmt.
- `just lint`: run statix, deadnix, Nix parsing, luacheck, shellcheck, and
  yamllint.
- `just test`: run the `nix-unit` tests for the current host architecture.
- `just check-nixos HOST`: dry-run build the NixOS toplevel for a host.
- `just check-hm USER`: dry-run build a Home Manager activation package.
- `just nixos-local build --flake .#HOST`: build a host without remote
  builders when full host validation is wanted.

## Directory Structure

- `flake.nix`: literal flake inputs. It imports `./outputs.nix` for outputs.
- `outputs.nix`: flake-parts composition root. It scans direct children of
  module/config directories into flake outputs.
- `parts/`: flake-parts modules for treefmt, pre-commit, nix-unit, and
  nix-topology.
- `justfile`: human workflow commands for formatting, linting, tests, rebuilds,
  dry-run checks, and package build/run helpers.
- `nixos-configurations/`: NixOS host directories. Each host has a
  `default.nix`, generated `hardware-configuration.nix`, and public keys under
  `keys/`.
- `nixos-modules/`: reusable NixOS modules. Direct children become
  `self.nixosModules.*`.
- `home-configurations/`: standalone Home Manager configurations. Currently
  only `darwin-example.nix`.
- `home-modules/`: reusable Home Manager modules. Direct children become
  `self.homeModules.*`.
- `nixvim-modules/`: nixvim module tree. Direct children become
  `self.nixvimModules.*`; the real editor root is
  `nixvim-modules/default/default.nix`.
- `shared-modules/`: modules usable from NixOS and standalone Home Manager,
  currently `age` and `stylix`.
- `overlays/`: repo overlay. It pulls packages from flake inputs, selected
  unstable packages, impure npx/uv wrappers, and a Proton Bridge override.
- `hax/`: small helper library. `hax/hosts.nix` derives host key, builder, and
  known-host information from configured hosts.
- `secrets/`: ragenix encrypted secrets plus recipient mapping in
  `secrets.nix`.
- `tests/`: nix-unit test entrypoint. It is currently empty.
- `README.md`: bootstrap notes for installing this repo onto a new machine.

## Flake Shape

`outputs.nix` uses `mkDirSet` and `mkImportSet` to turn directory children into
attributes. Adding, removing, or renaming a direct child of these directories can
change public flake outputs:

- `nixosConfigurations`: direct children of `nixos-configurations/`.
- `homeConfigurations`: direct children of `home-configurations/`.
- `nixosModules`: direct children of `nixos-modules/`.
- `homeModules`: direct children of `home-modules/`.
- `nixvimModules`: direct children of `nixvim-modules/`.
- `sharedModules`: direct children of `shared-modules/`.
- `overlays`: direct children of `overlays/`.

The per-system outputs currently include:

- `packages.neovim`: a nixvim-built Neovim using `self.nixvimModules.default`.
- `devShells.default`: repo tools and pre-commit hook installation.

The flake uses Nix's pipe operator (`|>`). If ad-hoc commands fail to parse it,
run inside the dev shell or pass the `pipe-operators` experimental feature.

## Hosts

- `anuramat-root`: server-like QEMU guest. Imports `nixosModules.default`,
  `nixosModules.anuramat`, and `./web`; uses GRUB on `/dev/vda`; hosts nginx,
  ACME, `ctrl.sn`, and `bin.ctrl.sn` via wastebin. `system.stateVersion` and
  Home Manager state are `24.11`.
- `anuramat-t480`: Lenovo ThinkPad T480. Imports `default`, `local`, `laptop`,
  `anuramat`, `nixos-hardware`'s T480 module, and hardware config. Uses TLP,
  keyd keyboard IDs, a swapfile, and captive-browser on `wlp3s0`.
  `system.stateVersion` is `24.05`; Home Manager state is `24.11`.
- `anuramat-f12`: Framework 12 13th-gen Intel laptop. Imports `default`,
  `local`, `laptop`, `anuramat`, Framework nixos-hardware, and hardware config.
  Has LUKS swap wiring, kanshi builtin-display data, keyd IDs, distributed
  builds, and captive-browser on `wlp0s20f3`. State versions are `25.05`.
- `anuramat-bgm5`: AMD/Strix Halo workstation. Imports `default`, `local`,
  `anuramat`, `builder`, local `llama`, `misc`, and `power` modules, plus AMD
  nixos-hardware and selected `nix-strix-halo` modules. It disables distributed
  builds, enables ROCm support, uses latest Linux, mounts `/mnt/storage`, adds a
  narrow Strix Halo overlay, configures quiet EC/fan behavior, enables Immich on
  Tailscale, and enables `codex-remote`. State versions are `25.11`.

## NixOS Modules

- `nixos-modules/default/`: baseline for every NixOS host. It imports agenix,
  Home Manager, nix-topology, common user/home/network/nix/web/llama modules,
  enables all firmware, iotop, and initrd systemd.
- `nixos-modules/default/nix.nix`: Nix settings, flakes, pipe-operators,
  registry/nixPath from inputs, substituters, trusted keys, remote build
  machines, `nh`, and `nix-serve`.
- `nixos-modules/default/net.nix`: firewall, NetworkManager, resolved,
  OpenConnect VPN, SSH, fail2ban, Tailscale, and known-host wiring.
- `nixos-modules/default/user.nix`: `userConfig`, primary user creation,
  groups, authorized keys, autologin user, and OpenRazer user hook.
- `nixos-modules/default/hosts.nix`: computes other hosts, builders,
  substituters, known-host files, authorized-key files, and cache keys.
- `nixos-modules/default/web.nix`: small `web.sites` abstraction that maps site
  records to nginx virtual hosts, ACME certs, and optional systemd services.
- `nixos-modules/default/llama.nix`: wraps NixOS `services.llama-cpp` with
  model-directory, model parameter, firewall, and flag generation options.
- `nixos-modules/local/`: workstation layer. It imports CUDA/ROCm conditionals,
  peripherals, keyd remaps, and rice; enables Waydroid, Podman with Docker
  compatibility, Steam, nix-ld, PipeWire, Bluetooth, CUPS, Avahi, udisks2,
  appimage binfmt, EFI/systemd-boot, GPU screen recorder, and heavy Home
  Manager modules.
- `nixos-modules/laptop.nix`: thermald, TLP defaults, and upower low-battery
  behavior.
- `nixos-modules/builder.nix`: creates the `builder` user for remote builds and
  asserts the host is not itself using distributed builds.
- `nixos-modules/anuramat.nix`: user identity and timezone defaults.

## Home Manager Modules

- `home-modules/default/`: base user environment: SSH aliases, XDG directories,
  bash/starship/readline, local shell scripts, git/delta/lazygit, yazi, search,
  typst preview helper, core CLI packages, GPG/password-store, and the custom
  `services.pss` secret service.
- `home-modules/linux.nix`: Linux-only user tools, bubblewrap/fuse-overlayfs,
  distrobox, hardware CLIs, Wayprompt pinentry selection, and `services.pss`.
- `home-modules/heavy/`: editor, GUI-independent media/document tools,
  language toolchains, email, nixvim Home Manager module, Spicetify, and
  heavier packages.
- `home-modules/heavy/gui/`: Firefox, browsers, document/media apps, OBS,
  viewers, terminals, theme hooks, Spicetify, and desktop app config files.
- `home-modules/heavy-linux/`: Linux desktop layer with agents, Niri desktop,
  terminal defaults, icon theme, screenshot/clipboard/display/audio helpers,
  and Wayland GUI utilities.
- `home-modules/heavy-linux/desktop/`: Niri, Waybar, swayidle/swaylock,
  kanshi, mako, xdg-desktop-portals, MIME handling, syncthing, clipboard, menu,
  and TTY autostart.
- `home-modules/heavy-linux/agents/`: AI tooling, prompt/instruction
  generation, bubblewrap sandbox wrappers, Codex/Claude/vicode frontends, mods
  config, and whisper transcription helper.
- `home-modules/darwin.nix` and `home-modules/standalone.nix`: standalone and
  Darwin Home Manager support.

## Nixvim

The Neovim setup is nixvim-based, not a hand-written `init.lua`. Activation path
on heavy hosts:

`inputs.nixvim.homeModules.nixvim -> home-modules/heavy/editor.nix -> self.nixvimModules.default -> nixvim-modules/default/default.nix`

Major parts:

- Core modules: `basic`, `completion`, `custom`, `dap`, `filemgr`, `fzf`, `git`,
  `image`, `lang`, `misc`, `treesitter`, `ui`, `vim`, `lib`, and `options`.
- Completion: `blink-cmp`, friendly snippets, and Copilot Lua. Copilot attaches
  only in selected repo paths such as `/etc/nixos` and `GHQ_ROOT`.
- Formatting/linting: `conform-nvim`, `none-ls`, `lint`, injected formatting,
  statix/deadnix/nixfmt, ruff/pyright, biome, shfmt/shellharden, yamlfmt, and
  language-specific formatters.
- Navigation/files: `fzf-lua`, Oil, Neo-tree, treesitter textobjects,
  treesitter context, TreeSJ, Flash, gitsigns, diffview, and DAP plugins.
- Languages: Nix, Rust with `rustaceanvim` and custom tree-climber integration,
  Python, web/TS/CSS/HTML, Lua, Go, Haskell, Lean, shell, Typst, Markdown, YAML,
  JSON, and miscellaneous language servers.
- `nixvim-modules/default/lib.nix` provides helpers for raw Lua, keymaps, and
  generating runtime files such as `after/ftplugin`, tree-sitter queries, and
  snippets.

## Important Software

- Nix operations: flakes, `nh`, `nix-serve`, Cachix and SSH substituters,
  distributed build host discovery, nix-unit, treefmt, pre-commit, statix,
  deadnix, nixfmt, nix-diff, nvd, dix, nix-tree, and nix-output-monitor.
- Desktop: Niri, Waybar, kanshi, mako, swayidle, swaylock-plugin, xdg portals
  including terminal file chooser, PipeWire/WirePlumber, Avahi, CUPS, udisks2,
  Blueman, NetworkManager applet, foot, Ghostty, Kitty, Firefox, Chrome,
  Tor Browser, Discord, Telegram, OBS, mpv, LibreOffice, Okular, Zathura,
  Zotero, Rnote, GIMP, Inkscape, Darktable, RawTherapee, and Spicetify.
- Development: Neovim/nixvim, Helix, Zed, Go, Python/uv, Node/Bun/Yarn, Lua,
  Haskell, Julia, Ruby, Perl, GCC/LLVM, gdb, delve, debugpy, shellcheck,
  luacheck, yamllint, treefmt, markdown tooling, jq/yq, quicktype, ghq, just,
  hyperfine, mprocs, and Git/delta/lazygit/difftastic.
- AI and agents: Codex, Claude Code, vicode, mods, Hermes, Copilot CLI,
  qwen-code, gemini-cli, MCP inspector, `ccusage`, `claude-monitor`, custom
  sandbox wrappers, generated instruction files, and API keys from ragenix.
- Secrets/keyring: ragenix, GPG, password-store, custom Rust
  `pass-secret-service` exposed as `services.pss`, Proton Pass CLI, libsecret,
  pam-gnupg regeneration, and the `tgfy` Telegram helper.
- GPU/ML/media: ROCm conditionals, CUDA conditionals, `ollama-rocm`,
  `llama-cpp-vulkan`, whisper-cpp, gpu-screen-recorder, `amd-debug-tools`,
  `amdgpu_top`, `rocm-smi`, ffmpeg, image/PDF tooling, and bgm5 Strix Halo EC
  and RyzenAdj controls.
- Server/web: nginx, ACME, `web.sites`, `ctrl.sn`, wastebin at `bin.ctrl.sn`,
  Immich on bgm5, Tailscale, OpenSSH, fail2ban, OpenConnect VPN, and
  NetworkManager.

## Secrets and Keys

- Encrypted secrets live as `secrets/*.age`.
- `shared-modules/age.nix` automatically creates `age.secrets` entries for
  every `.age` file under `secrets/`; on NixOS it sets the owner to the primary
  user.
- `secrets/secrets.nix` computes recipients from host client keys and host keys.
- Host public keys live under `nixos-configurations/$HOST/keys/`.
- `just nixos-pre` refreshes the current host's SSH host keys, public client
  keys, and binary-cache public key before rebuild-oriented commands.

## Surprising Or Complex Parts

- Direct directory children become public flake output names. A rename under
  `nixos-modules/`, `home-modules/`, `nixvim-modules/`, `shared-modules/`, or
  `nixos-configurations/` is an API change for this flake.
- `hax/hosts.nix` and `nixos-modules/default/hosts.nix` evaluate the host set to
  derive other hosts, builders, SSH key files, known-host files, cache
  substituters, and trusted cache keys. Small host changes can affect secrets,
  SSH, substituters, and remote-build behavior.
- The repo uses the experimental Nix pipe operator throughout modules and
  helper code. Raw parsing/eval commands may need `pipe-operators` enabled.
- `nixos-modules/builder.nix` asserts `!config.nix.distributedBuilds`; a builder
  host is modeled as a build server, not as a distributed-build client.
- The root flake is hand-maintained, but many outputs are still generated by
  directory scanning. Do not look for an `inputs.nix` or generated-flake
  pipeline.
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
- Waybar loads a fetched `waybar-niri-windows.so` release artifact by hash.
  Updating that component means updating the URL/hash pair.
- The desktop uses keyd home-row `lettermod` remaps plus host-specific keyboard
  IDs. Keyboard behavior is split between shared remaps and per-host IDs.
- bgm5 uses only selected attributes from the `nix-strix-halo` overlay instead
  of importing the whole upstream default overlay. Its quiet fan/EC behavior is
  in host-local `power.nix`.
- `shared-modules/stylix.nix` plus `nixos-modules/local/rice.nix` make theming a
  cross-cutting concern. A theme change can affect system boot visuals, desktop
  apps, terminals, and nixvim.
