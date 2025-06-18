{
  pkgs,
  inputs,
  osConfig,
  ...
}:
{
  programs = {
    nixvim = {
      enable = true;
      imports = [
        ./nixvim
      ];
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
    vscode
    vis
    zed-editor
  ];
}
