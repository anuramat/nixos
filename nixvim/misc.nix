{
  lib,
  myInputs,
  pkgs,
  ...
}:
{
  plugins = {
    todo-comments = {
      enable = true;
      settings = {
        signs = false;
        highlight = {
          keyword = "bg";
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
    {
      plugin = myInputs.wastebin-nvim.packages.${pkgs.system}.default;
      config = ''
        require('wastebin').setup({
          url = 'https://bin.ctrl.sn',
          open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
          ask = false,
        })
      '';
    }
  ];
}