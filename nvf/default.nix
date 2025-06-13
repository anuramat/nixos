{ pkgs, ... }:
{
  config.vim = {
    # why two?
    # treesitter.autotagHtml = true;
    # languages.html.treesitter.autotagHtml = true;

    git = {
      gitlinker-nvim.enable = true;
      gitsigns.enable = true;
      vim-fugitive.enable = true;
    };

    filetree.neo-tree.enable = true;
    formatter.conform-nvim.enable = true;
    fzf-lua.enable = true;
    lazy.enable = true;
    notes.todo-comments.enable = true;
    ui.colorizer.enable = true;

    mini = {
      ai.enable = true;
      align.enable = true;
      bracketed.enable = true;
    };
    treesitter = {
      context.enable = true;
      textobjects.enable = true;
    };
    utility = {
      images.image-nvim.enable = true;
      outline.aerial-nvim.enable = true;
      diffview-nvim.enable = true;
      oil-nvim.enable = true;
      surround.enable = true;
    };
    visuals = {
      fidget-nvim.enable = true;
      rainbow-delimiters.enable = true;
    };

    languages = {
      haskell.enable = true;
      nix.enable = true;
      python.enable = true;
      lua.enable = true;
      markdown.enable = true;

      go.enable = true;
      bash.enable = true;
      html.enable = true;
      clang.enable = true;

    };

    autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
    };

    lsp = {
      enable = true;
      lspconfig.enable = true;
      lightbulb.enable = true;
      otter-nvim.enable = true;
    };

    debugger.nvim-dap = {
      enable = true;
      ui.enable = true;
    };

    assistant = {
      avante-nvim.enable = true;
      copilot.enable = true;
    };

    viAlias = false;
    vimAlias = false;
  };
}
