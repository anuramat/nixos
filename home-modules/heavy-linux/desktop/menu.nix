{ lib, config, ... }:
{
  programs = {
    bemenu = {
      enable = true;
      settings = {
        fn =
          let
            font = config.stylix.fonts.monospace.name;
            size = toString config.stylix.fonts.sizes.applications;
          in
          lib.mkForce "${font} ${size}";
        line-height = 28;
        prompt = "open";
        list = 5;
        ignorecase = true;
      };
    };
  };
}
