{ pkgs, lib, ... }:
{
  settings.formatter = {
    shfmt.options = [
      "--case-indent"
      "--binary-next-line"
    ];
    shellharden = {
      includes = [ "*.sh*" ];
      command = lib.getExe pkgs.shellharden;
      options = [ "--replace" ];
    };
  };
  programs = {
    nixfmt.enable = true;
    shfmt = {
      enable = true;
      indent_size = 0;
    };
    yamlfmt.enable = true;
    black.enable = true;
    just.enable = true;
  };
}
