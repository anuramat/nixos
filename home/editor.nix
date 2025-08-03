{
  pkgs,
  hax,
  inputs,
  config,
  osConfig,
  cluster,
  ...
}:
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
          os-overlays = osConfig.nixpkgs.overlays;
        in
        if hm-overlays != null then hm-overlays else os-overlays;
      defaultEditor = true;
      _module.args = {
        inherit inputs hax;
      };
      plugins.lsp.servers.nixd.settings.options =
        let
          nixosExpr = ''(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${osConfig.networking.hostName}.options'';
        in
        {
          nixos.expr = nixosExpr;
          home-manager.expr = "${nixosExpr}.home-manager.users.type.getSubOptions []";
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
