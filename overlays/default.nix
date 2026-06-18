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
