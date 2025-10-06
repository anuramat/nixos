{
  config,
  ...
}:
{
  home.sessionVariables = {
    IPYTHONDIR = "${config.xdg.configHome}/ipython"; # ~/.ipython/; mixes configs with data
    PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
  };
  xdg.configFile = {
    "python/pythonrc".text = # python
      '''';
    "ipython/profile_default/startup/00-default.py".text = # python
      '''';
  };
  programs = {
    matplotlib = {
      enable = true;
      config = { };
    };
    uv.enable = true;
  };
}
