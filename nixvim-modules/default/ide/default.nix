{ hax, ... }:
{
  imports = [
    ./completion.nix
    ./dap.nix
  ];
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
    lint.enable = true;
    conform-nvim = {
      # the only formatter that can do injection formatting
      enable = true;
      settings = {
        format_on_save = {
          lsp_format = "fallback";
        };
      };
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
