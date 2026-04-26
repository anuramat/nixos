{ pkgs, ... }:
{
  extraPlugins = [
    (
      let
        rev = "002358ab6f0b4696b75905804ea7f1dca34a7ccd";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "tree_climber_rust.nvim";
        version = "nightly";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "adaszko";
          repo = "tree_climber_rust.nvim";
          sha256 = "0y1y7n1cysplhjpgzhacnk6g7lv2vdvwa5ip0gd8yrlikpzzqfqw";
        };
        dependencies = [ pkgs.vimPlugins.nvim-treesitter ];
      }
    )
  ];
}
