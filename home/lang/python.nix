{
  lib,
  hax,
  config,
  ...
}:
let
  # Convert nested attrset to Python config assignment statements
  toYAML = lib.generators.toYAML { };
in
{
  xdg.configFile."conda/condarc".text = toYAML {
    channels = [
      "conda-forge"
      "conda"
    ];
    auto_activate_base = false;
    changeps1 = false;
  };

  home.sessionVariables.JUPYTER_CONFIG_DIR = "${config.xdg.configHome}/jupyter"; # ~/.jupyter/
  xdg.configFile."jupyter/jupyter_server_config.py".text =
    let
      cfg = {
        ContentsManager.allow_hidden = false; # show .files
        ServerApp = {
          ip = "0.0.0.0";
          port = 8888;
          open_browser = false;
          password = "";
          token = "";
          disable_check_xsrf = true; # required by molten
        };
      };
      root = "c";
    in
    # python
    ''
      ${root} = get_config()
      ${hax.common.pythonConfig root cfg}
    '';

  home.sessionVariables.IPYTHONDIR = "${config.xdg.configHome}/ipython"; # ~/.ipython/; mixes configs with data
  xdg.configFile."ipython/profile_default/startup/00-default.py".text = # python
    '''';

  home.sessionVariables = {
    PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
  };
  xdg.configFile."python/pythonrc".text = # python
    '''';

  programs.matplotlib = {
    enable = true;
    config = { };
  };
}
