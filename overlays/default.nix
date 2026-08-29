{
  inputs,
  lib,
  ...
}:
let
  inherit (builtins)
    mapAttrs
    ;

  flakes =
    _: prev:
    (mapAttrs (_: v: v.packages.${prev.stdenv.hostPlatform.system}.default) {
      inherit (inputs)
        sem
        vicode
        subcat
        nil
        todo
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
        ;
    });

  overrides =
    final: prev:
    let
      unstable-misc = import inputs.nixpkgs-unstable-misc {
        inherit (prev) config;
        inherit (prev.stdenv.hostPlatform) system;
      };
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev) config;
        inherit (prev.stdenv.hostPlatform) system;
      };
    in
    {
      inherit (unstable)
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

      inherit (unstable-misc)
        firefox
        ghostty
        opencode
        proton-vpn
        rnote
        tombi
        typst
        google-chrome
        zed-editor
        ;

      darktable = unstable-misc.darktable.override {
        withAi = true;
        gmic = unstable-misc.gmic.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [ (prev.lib.cmakeBool "ENABLE_OPENCV" false) ];
        });
      };

      waybar-niri-windows = prev.buildGoModule {
        pname = "waybar-niri-windows";
        version = "unstable";
        src = inputs.waybar-niri-windows;
        vendorHash = "sha256-jK87vZYfUe8znk65SmJ1mN8qP5K3dtt950hKGWTYXs4=";
        nativeBuildInputs = [ prev.pkg-config ];
        buildInputs = [ prev.gtk3 ];
        buildPhase = "go build -buildmode=c-shared -o waybar-niri-windows.so ./main";
        installPhase = "install -Dm644 waybar-niri-windows.so $out/lib/waybar-niri-windows.so";
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
        inherit (unstable-misc.vimPlugins)
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

  overlays = [
    overrides
    flakes
    inputs.neovim-nightly-overlay.overlays.default
    inputs.oh-my-pi.overlays.default
  ];
in
final: prev:
let
  unwrapped = map (x: x final prev) overlays;
  merge = lib.foldr (a: b: a // b) { };
in
merge unwrapped
