{
  inputs,
  pkgs,
  ...
}:
{
  plugins = {
    copilot-lua = {
      enable = true;
      settings = {
        panel = {
          enabled = false;
        };
        suggestion = {
          enabled = false;
        };
      };
    };
  };

  # inputs.avante.packages.${pkgs.system}.default
}
