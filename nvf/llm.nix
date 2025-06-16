{
  vim.assistant = {
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

  pluginOverrides = {
    # avante-nvim = pkgs.fetchFromGitHub {
    #   owner = "yetone";
    #   repo = "avante.nvim";
    #   rev = "main";
    #   hash = "sha256-udiozhDynBCA0vDLnPsAdYCdiYKlFlnCgpzvbblQRuM=";
    # };
  };
}
