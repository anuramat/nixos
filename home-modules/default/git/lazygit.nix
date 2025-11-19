{
  home.shellAliases = {
    lg = "lazygit";
  };
  programs.lazygit = {
    enable = true;
    settings = {
      git.pagers = [ { externalDiffCommand = "difft"; } ];
    };
  };
}
