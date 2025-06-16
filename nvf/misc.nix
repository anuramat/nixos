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
        setupOpts = lib.mkOverride 0 { };
        enable = true;
      };
      copilot.enable = true;
    };

    pluginOverrides = {
      avante-nvim = pkgs.fetchFromGitHub {
        owner = "yetone";
        repo = "avante.nvim";
        rev = "main";
        hash = "sha256-udiozhDynBCA0vDLnPsAdYCdiYKlFlnCgpzvbblQRuM=";
      };
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
