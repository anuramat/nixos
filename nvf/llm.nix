{
  lib,
  myInputs,
  pkgs,
  ...
}:
{
  vim.assistant = {
    copilot = {
      enable = true;
      setupOpts = {
        panel = {
          enabled = false;
        };
        suggestion = {
          enabled = false;
        };
      };
    };
  };

  vim.extraPlugins = {
    avante = {
      package = myInputs.avante.packages.${pkgs.system}.default;

      setup =
        let
          inherit (lib.nvim.lua) toLuaObject;
          setupOpts = {
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
        in
        ''
          require('plugin').setup(${toLuaObject setupOpts})
        '';
    };
  };

  # pluginOverrides = {
  # avante-nvim = pkgs.fetchFromGitHub {
  #   owner = "yetone";
  #   repo = "avante.nvim";
  #   rev = "main";
  #   hash = "sha256-udiozhDynBCA0vDLnPsAdYCdiYKlFlnCgpzvbblQRuM=";
  # };
  # };
}
