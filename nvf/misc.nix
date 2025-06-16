{
  lib,
  myInputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  vim = {
    notes.todo-comments = {
      enable = true;
      setupOpts = {
        signs = false;
        mappings = {
          quickFix = mkForce null;
        };
        highlight = {
          keyword = "bg"; # only highlight the word itself
          pattern = ''<(KEYWORDS)>''; # vim regex
          multiline = false;
        };
        search = {
          pattern = ''\b(KEYWORDS)\b''; # ripgrep
        };
      };
    };

    assistant = {
      avante-nvim = {
        enable = true;
        setupOpts = mkForce {
          behaviour = {
            auto_suggestions = false;
          };
          providers = {
            copilot = {
              model = "claude-sonnet-4";
            };
          };
          windows = {
            ask = {
              floating = true;
              start_insert = false;
            };
            edit = {
              start_insert = false;
            };
            input = {
              height = 12;
              prefix = "";
            };
            position = "bottom";
            width = 40;
            wrap = true;
          };
        };
      };
      copilot.enable = true;
      # opts = {
      #   suggestion = {
      #     enabled = false,
      #   },
      #   panel = {
      #     enabled = false,
      #   },
      # },
    };

    pluginOverrides = {
      # avante-nvim = pkgs.fetchFromGitHub {
      #   owner = "yetone";
      #   repo = "avante.nvim";
      #   rev = "main";
      #   hash = "sha256-udiozhDynBCA0vDLnPsAdYCdiYKlFlnCgpzvbblQRuM=";
      # };
    };
    extraPlugins = {
      wastebin-nvim = {
        package = myInputs.wastebin-nvim.packages.${pkgs.system}.default;
        setup = ''
          require('wastebin').setup({
            url = 'https://bin.ctrl.sn',
            open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
            ask = false,
          })
        '';
      };
    };
  };
}
