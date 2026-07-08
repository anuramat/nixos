{
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib) luaf keymap;
in
{
  keymaps = [
    (keymap "n" "<leader>u" "<cmd>packadd nvim.undotree | Undotree<cr>" "Undotree")
    (keymap "n" "<leader>r" (luaf ''require("flash").jump()'') "Jump")
    (keymap "o" "r" (luaf ''require("flash").treesitter()'') "Treesitter node")
  ];

  inherit
    (config.lib.mkVimFiles {
      just.ftp.ts = 4;
    })
    files
    extraFiles
    ;

  plugins = {
    web-devicons.enable = true;
    sniprun.enable = true;
    grug-far.enable = true;
    schemastore.enable = true;
    dressing.enable = true;

    flash = {
      enable = true;
      settings = {
        label = {
          after = false;
          before = true;
        };
        modes = {
          char = {
            enabled = false;
          };
          treesitter = {
            grammars = [ pkgs.vimPlugins.nvim-treesitter-parsers.todotxt ];
            label = {
              rainbow = {
                enabled = true;
              };
            };
          };
        };
      };
    };

    todo-comments = {
      enable = true;
      settings = {
        keywords.SLOP = {
          icon = "󱚟";
          color = "warning";
        };
        keywords.FUCK = {
          icon = "💢";
          color = "warning";
        };
        signs = false;
        highlight = {
          keyword = "bg"; # only highlight the KEYWORD
          pattern = "<(KEYWORDS)>";
          multiline = false;
        };
        search = {
          pattern = ''\b(KEYWORDS)\b'';
        };
      };
    };
  };
}
