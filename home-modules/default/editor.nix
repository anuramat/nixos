{
  pkgs,
  hax,
  inputs,
  config,
  ...
}@args:
{
  stylix.targets = {
    neovim.plugin = "base16-nvim";
  };
  programs = {
    nixvim = {
      enable = true;
      imports = [
        ./nixvim
      ];
      nixpkgs.overlays =
        let
          hm-overlays = config.nixpkgs.overlays;
        in
        # TODO is this robust enough?
        if hm-overlays != null then hm-overlays else args.osConfig.nixpkgs.overlays;
      defaultEditor = true;
      _module.args = {
        inherit inputs hax;
      };
      plugins.lsp.servers.nixd.settings.options =
        if args ? osConfig then
          let
            nixosExpr = ''(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${args.osConfig.networking.hostName}.options'';
          in
          {
            nixos.expr = nixosExpr;
            home-manager.expr = "${nixosExpr}.home-manager.users.type.getSubOptions []";
          }
        else
          {
            # TODO standalone hm expression
          };
    };
    helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
        };
      };
    };
  };
  home.packages = with pkgs; [
    vis
  ];
}
