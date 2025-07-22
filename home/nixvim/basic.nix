{ hax, ... }:
{
  diagnostic.settings = {
    severity_sort = true;
    update_in_insert = true;
    signs = false;
  };
  extraConfigVim = builtins.readFile ./base.vim;

  opts = {
    formatoptions = "qj";
  };
  globals = {
    # tree style, symlinks are broken tho: https://github.com/neovim/neovim/issues/27301
    netrw_banner = 0;
    netrw_liststyle = 3;

    matchparen_timeout = 50;
    matchparen_insert_timeout = 50;

    nonfiles = [
      "NeogitStatus"
      "NeogitPopup"
      "oil"
      "lazy"
      "lspinfo"
      "null-ls-info"
      "NvimTree"
      "neo-tree"
      "alpha"
      "help"
      "fzf"
    ];
    markdown_fenced_languages = [
      "python"
      "lua"
      "vim"
      "haskell"
      "bash"
      "sh"
      "json5=json"
      "tex"
    ];
  };
  userCommands = {
    Trim = {
      command = "%s/ \\+$//g";
    };
  };
  keymaps =
    let
      inherit (hax.vim) set;
    in
    [
      (set "<c-j>" "cnext" "next qf item")
      (set "<c-k>" "cprev" "prev qf item")
    ];
}
