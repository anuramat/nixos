{ }:
{
  plugins.vimtex = {
    enable = true;
  };
  texlab = {
    settings = {
      texlab = {
        build = {
          forwardSearchAfter = true;
          onSave = true;
        };
        chktex = {
          onEdit = true;
          onOpenAndSave = true;
        };
        forwardSearch = {
          args = [
            "--synctex-forward"
            "%l:1:%f"
            "%p"
          ];
          executable = "zathura";
        };
      };
    };
  };
}
