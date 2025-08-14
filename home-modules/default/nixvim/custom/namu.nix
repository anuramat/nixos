{ pkgs, ... }:
{
  extraPlugins = [
    (
      let
        rev = "a3a3d81d12b61a38f131253bcd3ce5e2c6599850";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "namu.nvim";
        version = "nightly";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "bassamsdata";
          repo = "namu.nvim";
          sha256 = "04s6gh0ryhc6b487szqj3pkgynnx0xfr0b1q4c7kynf62bb4h4xa";
        };
      }
    )
  ];
  extraConfigLua = '''';
}
