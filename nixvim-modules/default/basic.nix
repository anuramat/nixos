{ config, ... }:
{
  diagnostic.settings = {
    severity_sort = true;
    update_in_insert = true;
    signs = false;
  };
  extraConfigVim = builtins.readFile ./base.vim;

  opts = {
    # q -- adds comment leader on format
    # r -- adds comment leader on newline
    # j -- removes leader on line join
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
  autoCmd = [
    {
      # $VIMRUNTIME ftplugins clobber the global value with their own
      # buffer-local one (e.g. sh.vim does `setlocal fo+=croql`); this fires
      # after them, since ftplugins are enabled before init is sourced
      # see :h ftplugin-overrule
      event = "FileType";
      command = "setlocal formatoptions=${config.opts.formatoptions}";
    }
  ];
  userCommands = {
    Trim = {
      command = "%s/ \\+$//g";
    };
  };
  keymaps =
    let
      inherit (config.lib) keymap;
    in
    [
      (keymap "n" "<c-j>" "<cmd>cnext<cr>" "next qf item")
      (keymap "n" "<c-k>" "<cmd>cprev<cr>" "prev qf item")
    ];
}
