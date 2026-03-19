{
  home.shellAliases = {
    lg = "lazygit";
  };
  programs.lazygit = {
    enable = true;
    settings = {
      promptToReturnFromSubprocess = false;
      git.pagers = [
        { externalDiffCommand = "difft"; }
        { pager = "delta --paging=never"; }
      ];
    };
  };
}
