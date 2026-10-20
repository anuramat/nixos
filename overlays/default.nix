{
  inputs,
  lib,
  ...
}:
let
  flakes =
    _: prev:
    (lib.mapAttrs (_: v: v.packages.${prev.stdenv.hostPlatform.system}.default) {
      inherit (inputs)
        sem
        vicode
        subcat
        nil
        statix
        deadnix
        html2text
        nix-auth
        claude-code
        codex
        hermes
        copilot-cli
        devin-cli
        chatgpt
        claude-desktop
        ghostty
        noctalia
        ctrlsn
        ;
    });

  overrides =
    final: prev:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev) config;
        inherit (prev.stdenv.hostPlatform) system;
      };
      unstable-slow = import inputs.nixpkgs-unstable-slow {
        inherit (prev) config;
        inherit (prev.stdenv.hostPlatform) system;
      };
    in
    {
      inherit (unstable-slow)
        linux-firmware
        linuxPackages_latest
        rocmPackages

        ollama
        ollama-rocm
        ollama-vulkan
        llama-cpp
        llama-cpp-rocm
        llama-cpp-vulkan
        ;

      inherit (unstable)
        firefox
        tailscale
        opencode
        proton-vpn
        rnote
        swayimg
        tombi
        typst
        google-chrome
        zed-editor
        yt-dlp
        ;

      # 0.49.1: kitten names shm objects with a leading slash, which ghostty requires
      kitty = unstable.kitty.overridePythonAttrs (old: rec {
        version = "0.49.1";
        src = old.src.override {
          tag = "v${version}";
          hash = "sha256-YVjTfJnsNEBjcHWQCq2nJBFPvLg7RqQcyWjgR4ijUqc=";
        };
        inherit
          (unstable.buildGo126Module {
            pname = "kitty-go-modules";
            inherit src version;
            vendorHash = "sha256-urQMf5lGYPgS65VjGw0pi/ZM6CETtGWfi/kvVDAkIoc=";
          })
          goModules
          ;
      });

      # inside zellij, yazi trusts the environment, which names the terminal zellij was first
      # started from, and only tries sixel; zellij 0.45 answers the image queries for the
      # attached terminals, and has kitty graphics, but no unicode placeholders
      yazi-unwrapped = prev.yazi-unwrapped.overrideAttrs {
        postPatch = ''
          substituteInPlace yazi-emulator/src/emulator.rs --replace-fail \
            'let resort = Brand::from_env();' \
            'let resort = if yazi_shared::env_exists("ZELLIJ_SESSION_NAME") { None } else { Brand::from_env() };'
          substituteInPlace yazi-adapter/src/adapter.rs --replace-fail \
            'adapters.retain(|p| *p == Self::Sixel);' \
            'adapters.retain(|p| *p != Self::Kgp);'
        '';
      };

      # compact-bar takes the "Zellij" text before the session name from a `prefix` config key;
      # zellij embeds its default plugins prebuilt, and only trusts embedded ones
      zellij-unwrapped =
        let
          compactBar = prev.pkgsCross.wasi32.rustPlatform.buildRustPackage {
            pname = "zellij-compact-bar";
            inherit (unstable.zellij-unwrapped) version src cargoDeps;
            patches = [ ./zellij-compact-bar-prefix.patch ];
            cargoBuildFlags = [ "-p compact-bar" ];
            # rustc passes wasm-ld flags, but nixpkgs makes the cc wrapper the linker
            env.RUSTFLAGS = "-Clinker=${lib.getExe' prev.lld "wasm-ld"}";
            doCheck = false;
            installPhase = "install -Dt $out target/*/release/compact-bar.wasm";
          };
        in
        unstable.zellij-unwrapped.overrideAttrs (old: {
          postPatch = old.postPatch + ''
            cp ${compactBar}/compact-bar.wasm zellij-utils/assets/plugins/
          '';
        });
      zellij = unstable.zellij.override { inherit (final) zellij-unwrapped; };

      darktable =
        (unstable.darktable.override {
          withAi = true;
          gmic = unstable.gmic.overrideAttrs (old: {
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [ (lib.cmakeBool "ENABLE_OPENCV" false) ];
          });
        }).overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ [ ./darktable-lua-info-rows.patch ];
          });

      nirimap = prev.rustPlatform.buildRustPackage {
        pname = "nirimap";
        version = "0.3.0";
        src = inputs.nirimap;
        cargoLock.lockFile = "${inputs.nirimap}/Cargo.lock";
        nativeBuildInputs = [
          prev.pkg-config
          prev.wrapGAppsHook4
        ];
        buildInputs = [
          prev.gtk4
          prev.gtk4-layer-shell
        ];
      };
      caut = prev.rustPlatform.buildRustPackage {
        pname = "caut";
        version = "0.1.0";
        src = inputs.caut;
        cargoLock.lockFile = "${inputs.caut}/Cargo.lock";
        patches = [
          # `cost`, `session` and `doctor` read ~/.claude and ~/.codex, ignoring CLAUDE_CONFIG_DIR and CODEX_HOME
          ./caut-env-dirs.patch
          # `session` looks for Claude logs in a `conversations/` dir, counts a Claude response's
          # usage once per content block, and misses most Codex usage
          ./caut-session-logs.patch
          # `doctor` and `usage` decode opaque OAuth tokens as JWTs, and flag a renewable access token
          ./caut-credential-health.patch
          # `cost` counts Claude's stats-cache messages and Codex log lines instead of pricing the
          # session logs; `session` prices a session at one model's rates, and takes a Claude
          # response's usage from its first line, before the output is complete
          ./caut-cost.patch
        ];
        # nightly-only `-Z threads` rustflag
        postPatch = "rm .cargo/config.toml";
        # vergen falls back to a `VERGEN_IDEMPOTENT_OUTPUT` placeholder without a git checkout
        env.VERGEN_GIT_SHA = inputs.caut.rev;
        env.VERGEN_GIT_DIRTY = "false";
        nativeBuildInputs = [
          prev.pkg-config
          prev.makeWrapper
        ];
        buildInputs = [ prev.sqlite ];
        # 11 LTO'd integration test binaries; upstream `cargo install` skips them too
        doCheck = false;
        # the codex on PATH is the agent sandbox wrapper, whose forced
        # --dangerously-bypass-approvals-and-sandbox conflicts with the `-s read-only -a never` of
        # caut's `codex app-server` fallback for an expired auth.json
        postFixup = "wrapProgram $out/bin/caut --prefix PATH : ${lib.makeBinPath [ final.codex ]}";
      };
      todo = prev.writers.writePython3Bin "todo" {
        # black-formatted: long lines, line breaks before binary operators
        flakeIgnore = [
          "E501"
          "W503"
        ];
      } (builtins.readFile ./todo.py);

      vimPlugins = prev.vimPlugins // {
        inherit (unstable.vimPlugins)
          tinted-nvim
          rustaceanvim
          ;
      };
    };
in
lib.composeManyExtensions [
  overrides
  flakes
  inputs.self.overlays.nx-studio
  inputs.self.overlays.pass-secret-service-rs
  inputs.self.overlays.proton-drive-cli
  inputs.self.overlays.tamron-lens-control
  inputs.self.overlays.vim-plugins
  inputs.neovim-nightly-overlay.overlays.default
  inputs.oh-my-pi.overlays.default
]
