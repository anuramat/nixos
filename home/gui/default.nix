{ inputs, pkgs, ... }:
{
  imports = [
    ./packages.nix
    ./desktop
    ./viewers.nix
    ./terminals.nix
    ./obs.nix
    ./theme.nix
  ];

  programs = {
    spicetify = {
      enable = true;
      enabledExtensions =
        let
          spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
        in
        with spicePkgs.extensions;
        [
          shuffle
          hidePodcasts
        ];
    };

    librewolf = {
      enable = true;
      settings = {
        "browser.urlbar.suggest.history" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "identity.fxaccounts.enabled" = true;

        # since it breaks a lot of pages
        "privacy.resistFingerprinting" = false;

        "sidebar.verticalTabs" = true;
        # required by vertical tabs
        "sidebar.revamp" = true;

        # rejecting all; fallback -- do nothing
        "cookiebanners.service.mode" = 1;
        "cookiebanners.service.mode.privateBrowsing" = 1;
      };
    };
  };
  stylix.targets.librewolf.profileNames = [ "default" ];
}
