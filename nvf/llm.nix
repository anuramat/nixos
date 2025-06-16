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
          require('avante').setup(${toLuaObject setupOpts})
        '';
    };
  };
  # good commit 574b0d37a32fcaf7ade1f76422ac4c8793af0301
  # pluginOverrides = {
  # avante-nvim = pkgs.fetchFromGitHub {
  #   owner = "yetone";
  #   repo = "avante.nvim";
  #   rev = "main";
  #   hash = "sha256-udiozhDynBCA0vDLnPsAdYCdiYKlFlnCgpzvbblQRuM=";
  # };
  # };
}
