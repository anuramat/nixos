{
  cluster,
  ...
}:
{
  imports = [
    ./common
    ./mime
    ./shell
    ./overlays
  ] ++ (if cluster.this.server then [ ./server ] else [ ./desktop ]);

  stylix = {
    enable = true;
    # autoEnable = false;
    polarity = "dark";
    homeManagerIntegration = {
      followSystem = true;
    };
    fonts = {
      monospace = {
        name = "Hack Nerd Font";
      };
      serif = {
        name = "Hack Nerd Font";
      };
      sansSerif = {
        name = "Hack Nerd Font";
      };
      sizes = {
        applications = 13;
        desktop = 10;
        popups = 10;
        terminal = 13;
      };
    };

    base16Scheme = {
      scheme = "zaibatsu";

      base00 = "#0e0024";
      base01 = "#d7005f";
      base02 = "#00af5f";
      base03 = "#ffaf00";
      base04 = "#5f5fff";
      base05 = "#d700ff";
      base06 = "#00afff";
      base07 = "#d7d5db";
      base08 = "#878092";
      base09 = "#ff5faf";
      base0A = "#00d700";
      base0B = "#ffd700";
      base0C = "#8787ff";
      base0D = "#ff87ff";
      base0E = "#00ffff";
      base0F = "#ffffff";
    };
  };
  # "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  programs.npm = {
    npmrc = ''
      prefix=''${XDG_DATA_HOME}/npm
      cache=''${XDG_CACHE_HOME}/npm
      tmp=''${XDG_RUNTIME_DIR}/npm
      init-module=''${XDG_CONFIG_HOME}/npm/config/npm-init.js
    '';
  };

  # add login later
  security.pam.services.login.gnupg = {
    enable = true;
    noAutostart = true;
  };
  security.pam.services.swaylock.gnupg = {
    enable = true;
    noAutostart = true;
  };
}
