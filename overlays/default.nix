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
      tamron-lens-control = prev.rustPlatform.buildRustPackage {
        pname = "tamron-lens-control";
        version = "0.1.1-dev";
        src = inputs.tamron-lens-control;
        cargoLock.lockFile = "${inputs.tamron-lens-control}/Cargo.lock";
        nativeBuildInputs = [ prev.pkg-config ];
        buildInputs = [ prev.udev ]; # serialport enumeration
        meta.mainProgram = "tlc";
      };
      todo = prev.writers.writePython3Bin "todo" {
        # black-formatted: long lines, line breaks before binary operators
        flakeIgnore = [
          "E501"
          "W503"
        ];
      } (builtins.readFile ./todo.py);
      zotero-mcp = prev.python3Packages.buildPythonApplication {
        # basic build without semantic features
        pname = "zotero-mcp";
        version = "0.6.1";
        pyproject = true;
        src = inputs.zotero-mcp;
        build-system = [ prev.python3Packages.hatchling ];
        dependencies = with prev.python3Packages; [
          pyzotero
          mcp
          python-dotenv
          markitdown
          pydantic
          requests
          fastmcp
          unidecode
          bibtexparser
        ];
        pythonImportsCheck = [ "zotero_mcp" ];
      };

      vimPlugins = prev.vimPlugins // {
        inherit (unstable.vimPlugins)
          tinted-nvim
          rustaceanvim
          ;
        figtree-nvim = inputs.figtree.packages.${prev.stdenv.hostPlatform.system}.default;
        wastebin-nvim = prev.vimUtils.buildVimPlugin {
          pname = "wastebin.nvim";
          version = "nightly";
          src = inputs.wastebin-nvim;
        };
        tree-climber-rust-nvim = prev.vimUtils.buildVimPlugin {
          pname = "tree_climber_rust.nvim";
          version = "nightly";
          src = inputs.tree-climber-rust-nvim;
          dependencies = [ prev.vimPlugins.nvim-treesitter ];
          postPatch = ''
            substituteInPlace lua/tree_climber_rust.lua \
              --replace-fail 'local ts_utils = require("nvim-treesitter.ts_utils")' '
            local function get_vim_range(range, buf)
                local srow, scol, erow, ecol = unpack(range)
                srow = srow + 1
                scol = scol + 1
                erow = erow + 1
                if ecol == 0 then
                    erow = erow - 1
                    if buf and buf ~= 0 then
                        ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
                    else
                        ecol = vim.fn.col { erow, "$" } - 1
                    end
                    ecol = math.max(ecol, 1)
                end
                return srow, scol, erow, ecol
            end

            local function get_node_at_cursor()
                return ts.get_node({ ignore_injections = false })
            end' \
              --replace-fail 'local parsers = require("nvim-treesitter.parsers")' "" \
              --replace-fail 'ts_utils.get_vim_range' 'get_vim_range' \
              --replace-fail 'ts_utils.get_node_at_cursor()' 'get_node_at_cursor()' \
              --replace-fail 'parsers.get_parser(buf):parse()[1]:root()' 'assert(ts.get_parser(buf)):parse()[1]:root()'
          '';
        };
      };
    };
in
lib.composeManyExtensions [
  overrides
  flakes
  inputs.self.overlays.nx-studio
  inputs.self.overlays.pass-secret-service-rs
  inputs.self.overlays.proton-drive-cli
  inputs.neovim-nightly-overlay.overlays.default
  inputs.oh-my-pi.overlays.default
]
