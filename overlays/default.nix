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
        immich # 2.x is EOL and marked insecure in 26.05
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

  # 0.7.0, which bgm5's llama.cpp patch (noncausal_suffix) is made against;
  # drop once nixpkgs-unstable-slow has it
  llamaCpp =
    _: prev:
    lib.genAttrs [ "llama-cpp" "llama-cpp-rocm" "llama-cpp-vulkan" ] (
      name:
      prev.${name}.overrideAttrs (old: {
        version = "0.7.0";
        src = old.src.override { hash = "sha256-pEDYgI3AMTU+cekvRX7NNt5wddznydQSNuerswvEpsA="; };
        patches = [ ];
        npmDepsHash = "sha256-hqYzdp1FwPhYkBP278fQXgY9NCKB6Q3P6Gko7BfP0m0=";
        disabledTests = old.disabledTests ++ [ "test-llama-context-model" ];
      })
    );

  # bgm5 uploads slowly: fetch big prebuilt binaries from upstream and wrap them locally,
  # instead of substituting from (or building on) bgm5; only for versioned download URLs
  upstreamOnly =
    _: prev:
    let
      local =
        drv:
        drv.overrideAttrs {
          allowSubstitutes = false;
          preferLocalBuild = true;
        };
      upstream = fetchurl: a: fetchurl (a // { derivationArgs.allowSubstitutes = false; });
    in
    lib.genAttrs [ "claude-code" "codex" "claude-desktop" ] (
      name:
      local (
        prev.${name}.override (o: {
          fetchurl = upstream o.fetchurl;
        })
      )
    )
    // {
      # `latest` moves on every release; the apt pool keeps every version
      chatgpt = local (
        prev.chatgpt.override (o: {
          fetchurl =
            a:
            let
              latest = "/deb/latest/chatgpt_";
            in
            assert lib.assertMsg (lib.hasInfix latest a.url) "chatgpt: unexpected download URL ${a.url}";
            upstream o.fetchurl (
              a
              // {
                url =
                  lib.replaceStrings [ latest ] [ "/deb/pool/main/c/chatgpt/chatgpt_${prev.chatgpt.version}_" ]
                    a.url;
              }
            );
        })
      );
    };
in
lib.composeManyExtensions [
  overrides
  llamaCpp
  flakes
  upstreamOnly
  inputs.self.overlays.caut
  # `codex` is the agent sandbox wrapper (home-modules/heavy-linux/agents)
  (_: prev: { caut = prev.caut.override { codex = "codex-unboxed"; }; })
  inputs.self.overlays.niri
  inputs.self.overlays.nx-studio
  inputs.self.overlays.pass-secret-service-rs
  inputs.self.overlays.proton-drive-cli
  inputs.self.overlays.qev
  inputs.self.overlays.tamron-lens-control
  inputs.self.overlays.vim-plugins
  inputs.self.overlays.wvkbd
  inputs.neovim-nightly-overlay.overlays.default
  inputs.oh-my-pi.overlays.default
]
