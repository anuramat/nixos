{ pkgs, ... }:
{
  extraPlugins = [
    (
      let
        rev = "7a70a7e5efc2af5025134c395bd27e3ada9b8629";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "wastebin.nvim";
        version = "nightly";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "matze";
          repo = "wastebin.nvim";
          sha256 = "0r5vhmd30zjnfld9xvcpyjfdai1bqsbw9w6y51d36x3nsxhjbm2y";
        };
      }
    )
  ];
  extraConfigLua = ''
    require('wastebin').setup({
      url = 'https://bin.ctrl.sn',
      open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
      ask = false,
    })
  '';
}
