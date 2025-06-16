{
  lib,
  inputs,
  pkgs,
  ...
}:
{
  plugins = {
  undotree.enable= true;
    todo-comments = {
      enable = true;
      settings = {
        signs = false;
        highlight = {
          keyword = "bg"; # only highlight the KEYWORD
          pattern = ''<(KEYWORDS)>'';
          multiline = false;
        };
        search = {
          pattern = ''\b(KEYWORDS)\b'';
        };
      };
    };
  };

  extraPlugins = [
    inputs.wastebin-nvim.packages.${pkgs.system}.default
  ];

  extraConfigLua = ''
    require('wastebin').setup({
      url = 'https://bin.ctrl.sn',
      open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
      ask = false,
    })
  '';
}
