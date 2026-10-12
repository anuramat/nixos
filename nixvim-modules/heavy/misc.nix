{
  config,
  ...
}:
let
  inherit (config.lib) keymap cmd;
in
{
  keymaps = [
    (cmd "n" "<leader>u" "packadd nvim.undotree | Undotree" "Undotree")
    (keymap "n" "<leader>r" { __raw = ''function() require("flash").jump() end''; } "Jump")
    (keymap "o" "r" { __raw = ''function() require("flash").treesitter() end''; } "Treesitter node")
  ];

  plugins = {
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
