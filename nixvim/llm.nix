{
  lib,
  myInputs,
  pkgs,
  ...
}:
{
  plugins = {
    copilot-lua = {
      enable = true;
      settings = {
        panel = {
          enabled = false;
        };
        suggestion = {
          enabled = false;
        };
      };
    };
  };

  extraPlugins = [
    {
      plugin = myInputs.avante.packages.${pkgs.system}.default;
      config = ''
        require('avante').setup({
          behaviour = {
            auto_suggestions = false,
          },
          providers = {
            copilot = {
              model = "claude-sonnet-4",
            },
          },
          windows = {
            ask = {
              floating = true,
              start_insert = false,
            },
            edit = {
              start_insert = false,
            },
            input = {
              height = 12,
              prefix = "",
            },
            position = "bottom",
            width = 40,
            wrap = true,
          },
        })
      '';
    }
  ];
}
