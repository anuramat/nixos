{
  config,
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    IPYTHONDIR = "${config.xdg.configHome}/ipython"; # ~/.ipython/; mixes configs with data
    PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
  };
  programs = {
    matplotlib.enable = true;
    uv.enable = true;
  };
  home.packages = with pkgs; [
    python3Packages.ptpython
  ];
}
