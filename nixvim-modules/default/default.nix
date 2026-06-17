{
  config,
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [
    inputs.self.overlays.default
  ];
  imports = [
    ./basic.nix
    ./completion.nix
    ./custom
    ./filemgr.nix
    ./fzf.nix
    ./git.nix
    ./image.nix
    ./lang
    ./misc.nix
    ./tags.nix
    ./treesitter.nix
    ./ui.nix
    ./editing.nix
    ./lib.nix
  ];

  extraPlugins = [
    pkgs.vimPlugins.tinted-nvim
  ];
  luaLoader.enable = true;

  keymaps =
    let
      inherit (config.lib) lua keymap;
    in
    [
      (keymap "n" "grd" (lua "vim.lsp.buf.declaration") "Goto Declaration")
      (keymap "n" "grq" (lua "vim.diagnostic.setqflist") "Diagnostic QF List")
    ];
  plugins = {
    lint = {
      enable = true;
      autoCmd.event = [
        "BufWritePost"
        "FileType"
      ];
    };
    conform-nvim = {
      # the only formatter that can do injection formatting
      enable = true;
      autoInstall.enable = true;
      settings = {
        formatters = {
          injected = {
            ignore_errors = true;
          };
        };
        format_on_save = {
          timeout_ms = 300;
        };
        notify_on_error = false;
        default_format_opts = {
          timeout_ms = 3000;
          lsp_format = "fallback";
          quiet = true;
        };
      };
    };
    none-ls.enable = true;
    lsp = {
      enable = true;
      inlayHints = false;
      # TODO enable for typst?
      onAttach = # lua
        ''
          if vim.o.ft == "markdown" then require("otter").activate() end
        '';
    };
    otter = {
      # lsp for codeblocks in markdown
      # TODO make sure it doesn't format twice (conform + otter)
      enable = true;
      settings = {
        handle_leading_whitespace = true;
      };
      autoActivate = false; # TODO
    };
  };
}
