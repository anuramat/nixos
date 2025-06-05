{
  cluster,
  inputs,
  pkgs,
  ...
}:
{
  imports =
    [
      ./common
      ./mime
      ./shell
      ./overlays
      ./home.nix
    ]
    ++ (
      if cluster.this.server then
        [
          ./server
        ]
      else
        [
          ./desktop
        ]
    );

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
