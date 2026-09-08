{
  home.shellAliases = {
    lg = "lazygit";
  };
  programs.lazygit = {
    enable = true;
    settings = {
      promptToReturnFromSubprocess = false;
      git.pagers = [
        { pager = "delta --paging=never"; }
        { externalDiffCommand = "difft"; }
      ];
    };
  };
}
