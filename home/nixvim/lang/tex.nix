{
  plugins = {
    vimtex = {
      enable = true;
    };
    lsp.servers.texlab = {
      enable = true;
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
  };
}
