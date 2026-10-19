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
    _final: prev:
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
        zellij
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

      darktable = unstable.darktable.override {
        withAi = true;
        gmic = unstable.gmic.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [ (lib.cmakeBool "ENABLE_OPENCV" false) ];
        });
      };

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
        # nightly-only `-Z threads` rustflag
        postPatch = "rm .cargo/config.toml";
        nativeBuildInputs = [ prev.pkg-config ];
        buildInputs = [ prev.sqlite ];
        # 11 LTO'd integration test binaries; upstream `cargo install` skips them too
        doCheck = false;
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
