{
  cluster,
  inputs,
  pkgs,
  ...
}:
{
  hardware.graphics.enable = true;
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./common
    ./mime
    ./shell
    ./overlays
  ] ++ (if cluster.this.server then [ ./server ] else [ ./desktop ]);

  stylix.homeManagerIntegration.followSystem = true;

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
