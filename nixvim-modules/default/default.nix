# hover.nvim
# nvim-genghis
# https://github.com/netmute/ctags-lsp.nvim
# https://github.com/netmute/ctags-lsp
# https://github.com/dhananjaylatkar/cscope_maps.nvim
# https://github.com/ludovicchabant/vim-gutentags
# https://github.com/danymat/neogen
# https://github.com/kristijanhusak/vim-dadbod-completion
# https://github.com/tpope/vim-dadbod
# https://github.com/kristijanhusak/vim-dadbod-ui
# https://github.com/nvim-neotest/neotest
# https://github.com/mattn/efm-langserver
{
  inputs,
  hax,
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
    ./dap.nix
    ./filemgr.nix
    ./ft.nix
    ./fzf.nix
    ./git.nix
    ./lang
    ./misc.nix
    ./treesitter.nix
    ./ui.nix
    ./vim.nix
  ];

  plugins.lz-n.enable = true;
  luaLoader.enable = true;
  performance = {
    combinePlugins = {
      enable = false;
      standalonePlugins = [
      ];
    };
    byteCompileLua = {
      enable = false;
      initLua = true;
      configs = true;
      plugins = true;
      nvimRuntime = true;
      luaLib = true;
    };
  };

  viAlias = false;
  vimAlias = false;

  keymaps =
    let
      inherit (hax.vim) lua;
      set = key: hax.vim.set ("gr" + key);
    in
    [
      (set "d" (lua "vim.lsp.buf.declaration") "Goto Declaration")
      (set "q" (lua "vim.diagnostic.setqflist") "Diagnostic QF List")
      (set "l" (lua "vim.lsp.codelens.run") "CodeLens")
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
      # autoInstall.enable = true; # TODO coming soon
      settings = {
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
    none-ls = {
      enable = true;
    };
    overseer = {
      # tasks
      settings = {
        task_list = {
          default_detail = 1;
          direction = "bottom";
          max_height = 25;
          min_height = 25;
        };
      };
    };
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
