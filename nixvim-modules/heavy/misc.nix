{
  config,
  ...
}:
let
  inherit (config.lib) keymap;
in
{
  keymaps = [
    (keymap "n" "<leader>u" "<cmd>packadd nvim.undotree | Undotree<cr>" "Undotree")
    (keymap "n" "<leader>r" { __raw = ''function() require("flash").jump() end''; } "Jump")
    (keymap "o" "r" { __raw = ''function() require("flash").treesitter() end''; } "Treesitter node")
  ];

  inherit
    (config.lib.mkVimFiles {
      just.ftp.ts = 4;
    })
    files
    extraFiles
    ;

  plugins = {
    sniprun.enable = true;
    grug-far.enable = true;
    schemastore.enable = true;
    dressing.enable = true;
    conform-nvim.settings.formatters_by_ft.just = [ "just" ];

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
