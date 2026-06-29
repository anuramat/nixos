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
        mods
        todo
        statix
        deadnix
        html2text
        nix-auth
        claude-code
        codex
        zed-editor
        hermes
        copilot-cli
        ;
    });

  unstablePkgs =
    _: prev:
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
        swaylock-plugin
        tombi
        typst
        google-chrome
        ;

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

  impureWrappers =
    _: prev:
    let
      mkNpx =
        binName: pkg:
        let
          npx = prev.lib.getExe' prev.nodejs "npx";
        in
        prev.writeShellScriptBin binName ''
          exec ${npx} -y ${pkg} "$@"
        '';
      mkUv =
        binName: pkg:
        let
          uv = prev.lib.getExe prev.uv;
        in
        prev.writeShellScriptBin binName ''
          exec ${uv} tool run ${pkg} "$@"
        '';
    in
    {
      qwen-code = mkNpx "qwen-code" "@qwen-code/qwen-code";
      gemini-cli = mkNpx "gemini" "@google/gemini-cli";
      inspector = mkNpx "inspector" "@modelcontextprotocol/inspector";
      ccusage = mkNpx "ccusage" "ccusage";
      claude-monitor = mkUv "claude-monitor" "claude-monitor";
    };

  # llama.cpp PR 24423 (DiffusionGemma) on top of a nixpkgs llama-cpp variant
  diffusionGemma =
    pkg:
    pkg.overrideAttrs (old: {
      version = "24423"; # PR number; must be numeric (becomes LLAMA_BUILD_NUMBER)
      src = inputs.llama-cpp-diffusion;
      npmDepsHash = "sha256-pjdbI6NcZRlJVd62xhgbLhWrwFYwgsIwjORqvo1+VD8=";
      # nixpkgs creates COMMIT in postFetch; diffusion-cli lives in examples/
      postPatch = "echo ${inputs.llama-cpp-diffusion.shortRev} > COMMIT";
      cmakeFlags = old.cmakeFlags ++ [ "-DLLAMA_BUILD_EXAMPLES=ON" ];
    });

  freeform = final: prev: {
    llama-cpp-diffusion-vulkan = diffusionGemma final.llama-cpp-vulkan;
    llama-cpp-diffusion-rocm = diffusionGemma final.llama-cpp-rocm;
    protonmail-bridge = prev.protonmail-bridge.overrideAttrs (_: {
      version = "unstable";
      src = inputs.protonmail-bridge;
      vendorHash = "sha256-aW7N6uacoP99kpvw9E5WrHaQ0fZ4P5WGsNvR/FAZ+cA=";
    });
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
  };

  inputOverlays =
    with inputs;
    [
      neovim-nightly-overlay
    ]
    |> map (v: v.overlays.default);

  overlays = inputOverlays ++ [
    freeform
    impureWrappers
    unstablePkgs
    flakes
  ];
in
final: prev:
let
  unwrapped = map (x: x final prev) overlays;
  merge = lib.foldr (a: b: a // b) { };
in
merge unwrapped
