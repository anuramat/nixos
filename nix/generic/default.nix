{
  cluster,
  pkgs,
  ...
}:
{
  hardware.graphics.enable = true;
  imports = [
    ./common
    ./mime
    ./shell
    ./overlays
  ] ++ (if cluster.this.server then [ ./server ] else [ ./desktop ]);

  stylix = {
    enable = true;
    autoEnable = true;
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
    # stella
    # black-metal
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  };
  # TODO uhh
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
