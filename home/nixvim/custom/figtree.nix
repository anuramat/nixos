{ pkgs, ... }:
{
  extraPlugins = [
    (
      let
        rev = "062fd90490ddd9c2c5b749522b0906d4a2d74f72";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "figtree.nvim";
        version = "nightly";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "anuramat";
          repo = "figtree.nvim";
          sha256 = "08xzv1h3v3xkyx4v0l068i65qvly9mxjnpswd33gb5al1mfqdmbg";
        };
      }
    )
  ];
  extraConfigLua = ''
    require('figtree').setup({
    })
  '';
}
