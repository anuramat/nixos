{ pkgs, ... }:
{
  extraPlugins = [
    (
      let
        rev = "a54a2a180dc40f4d85875eeafacbdf991d042a36";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "mini.bracketed";
        version = "nightly";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "echasnovski";
          repo = "mini.bracketed";
          sha256 = "sha256-ZvoAOCdwAx1Xo2Drk/T18T6KTuW9PUYQt964VUP4vzc=";
        };
      }
    )
  ];
  extraConfigLua = ''
    require('mini.bracketed').setup()
  '';
}
