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
        nil
        statix
        deadnix
        nix-auth
        claude-code
        codex
        chatgpt
        claude-desktop
        ghostty
        noctalia
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
      # attached terminals, and has kitty graphics, but no unicode placeholders;
      # yazi looks for terminal names in all the replies, and takes zellij's "kitty graphics not
      # supported" for kitty;
      # over plain ssh images are too slow, so they're drawn as text blocks;
      # previewers also run when the preview pane is hidden, drawing to an empty area;
      # plugins can't sort files, so the `sort exif-*` modes order them by whatever the exif
      # plugin puts in the directory size map, the only per-file data plugins can hand to the sorter
      yazi-unwrapped = prev.yazi-unwrapped.overrideAttrs {
        postPatch = ''
          substituteInPlace yazi-emulator/src/emulator.rs --replace-fail \
            'let resort = Brand::from_env();' \
            'let resort = if yazi_shared::env_exists("ZELLIJ_SESSION_NAME") { None } else { Brand::from_env() };' --replace-fail \
            'Brand::from_csi(&resp).or(resort)' \
            'Brand::from_csi(&resp).filter(|_| !yazi_shared::env_exists("ZELLIJ_SESSION_NAME")).or(resort)'
          substituteInPlace yazi-adapter/src/adapter.rs --replace-fail \
            'adapters.retain(|p| *p == Self::Sixel);' \
            'adapters.retain(|p| *p != Self::Kgp);' --replace-fail \
            'let mut adapters: Adapters = emulator.into();' \
            'if yazi_shared::in_ssh_connection() && !env_exists("ZELLIJ_SESSION_NAME") { return Self::Chafa; }
            let mut adapters: Adapters = emulator.into();'
          substituteInPlace yazi-core/src/tab/preview.rs --replace-fail \
            'YAZI.plugin.previewers.matches(&file, &mime) else {' \
            'YAZI.plugin.previewers.matches(&file, &mime).filter(|_| !LAYOUT.get().preview.is_empty()) else {'
          substituteInPlace yazi-fs/src/sorting.rs --replace-fail \
            'Random,' \
            'Random, ExifDate, ExifShutter,'
          substituteInPlace yazi-fs/src/files.rs --replace-fail \
            'if self.sorter.by == SortBy::Size {' \
            'if matches!(self.sorter.by, SortBy::Size | SortBy::ExifDate | SortBy::ExifShutter) {'
          substituteInPlace yazi-fs/src/sorter.rs --replace-fail \
            'SortBy::Random => {' \
            'SortBy::ExifDate | SortBy::ExifShutter => items.sort_unstable_by(|a, b| {
              promote!(a, b);
              self.fallback(a, b, self.cmp(sizes.get(&a.urn()), sizes.get(&b.urn())))
            }),
            SortBy::Random => {'
        '';
      };

      # compact-bar takes the "Zellij" text before the session name from a `prefix` config key;
      # zellij embeds its default plugins prebuilt, and only trusts embedded ones;
      # images are too slow over ssh, so a client attached over ssh reports no image support:
      # zellij answers the image queries for the attached clients, and sends images only to
      # the ones that support them; panes made by a plain, floating or stacked NewPane aren't
      # told what the attached clients support, and answer as if they supported everything;
      # 0.45 has no unicode placeholders, which neovim places its images with: the patch is
      # https://github.com/zellij-org/zellij/pull/5531, rebased for 0.46 in pull/5878
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
          patches = old.patches or [ ] ++ [
            (final.fetchpatch {
              url = "https://github.com/zellij-org/zellij/compare/b0bd3e1e7f530db8879e8cbde79de245e6101a8a...3a1af548d857aaafa428e97df59003a1dcc28f8b.diff";
              hash = "sha256-0EBd1tFOyYLu116Eavauh8VbHeKCzgus3e8XCI/tnms=";
            })
          ];
          postPatch = old.postPatch + ''
            cp ${compactBar}/compact-bar.wasm zellij-utils/assets/plugins/
            substituteInPlace zellij-client/src/lib.rs --replace-fail \
              'let support_kitty_graphics_protocol = config_options' \
              'let support_kitty_graphics_protocol = std::env::var_os("SSH_CONNECTION").is_none() && config_options'
            substituteInPlace zellij-client/src/stdin_ansi_parser.rs --replace-fail \
              '.any(|attribute| attribute == "4")' \
              '.any(|attribute| attribute == "4") && std::env::var_os("SSH_CONNECTION").is_none()'
            substituteInPlace zellij-server/src/tab/mod.rs --replace-fail \
              ')) as Box<dyn Pane>
                        },
                    };' \
              ')) as Box<dyn Pane>
                        },
                    };
                    if let Some(supported) = self.kitty_host_support {
                        new_pane.update_kitty_host_support(supported);
                    }
                    if let Some(supported) = self.sixel_host_support {
                        new_pane.update_sixel_host_support(supported);
                    }'
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

      # `trash empty` asserts that every info file's payload exists, following symlinks, so it
      # panics on an orphaned info file or a trashed dangling symlink
      trashy = prev.trashy.overrideAttrs {
        postPatch = ''
          substituteInPlace $cargoDepsCopy/source-registry-0/trash-2.1.5/src/freedesktop.rs \
            --replace-fail 'assert!(file.exists());' \
            'if file.symlink_metadata().is_err() {
              std::fs::remove_file(info_file).map_err(|e| fsys_err_to_unknown(&info_file, e))?;
              continue;
            }'
        '';
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
        # an image gives way to its source under the cursor, but kept the lines it had no rows
        # for hidden
        snacks-nvim = prev.vimPlugins.snacks-nvim.overrideAttrs (old: {
          postPatch = old.postPatch or "" + ''
            substituteInPlace lua/snacks/image/placement.lua \
              --replace-fail 'e.conceal = nil' 'e.conceal, e.conceal_lines = nil, nil'
          '';
        });
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
    lib.genAttrs [ "claude-code" "codex" "chatgpt" "claude-desktop" ] (
      name:
      local (
        prev.${name}.override (o: {
          fetchurl = upstream o.fetchurl;
        })
      )
    );
in
lib.composeManyExtensions [
  overrides
  llamaCpp
  flakes
  upstreamOnly
  inputs.self.overlays.ancs4linux
  inputs.self.overlays.facet
  inputs.self.overlays.figtree
  inputs.self.overlays.niri
  inputs.self.overlays.nx-studio
  inputs.self.overlays.pass-secret-service-rs
  inputs.self.overlays.proton-drive-cli
  inputs.self.overlays.qev
  inputs.self.overlays.tamron-lens-control
  inputs.self.overlays.typst-eq
  inputs.self.overlays.vim-plugins
  inputs.self.overlays.wvkbd
  inputs.neovim-nightly-overlay.overlays.default
]
