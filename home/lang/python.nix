{
  lib,
  hax,
  config,
  ...
}:
let
  # Convert nested attrset to Python config assignment statements
  toYAML = lib.generators.toYAML { };
  toJSON = lib.generators.toJSON { };
in
{
  home.sessionVariables.JUPYTER_CONFIG_DIR = "${config.xdg.configHome}/jupyter"; # ~/.jupyter/
  xdg.configFile = (
    {
      "python/pythonrc".text = # python
        '''';
      "ipython/profile_default/startup/00-default.py".text = # python
        '''';
      "conda/condarc".text = toYAML {
        channels = [
          "conda-forge"
          "conda"
        ];
        auto_activate_base = false;
        changeps1 = false;
      };
      "jupyter/jupyter_server_config.py".text =
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
    }
    // (
      let
        mkSettingsJSON =
          root: settings:
          settings
          |> lib.mapAttrs' (path: contents: lib.nameValuePair (root + path) { text = (toJSON contents); });
      in
      mkSettingsJSON "jupyter/lab/user-settings/@jupyterlab/" {
        "docmanager-extension/plugin.jupyterlab-settings" = {
          autosave = false;
        };
        "extensionmanager-extension/plugin.jupyterlab-settings" = {
          disclaimed = true;
        };
        "apputils-extension/notification.jupyterlab-settings" = {
          fetchNews = false;
          checkForUpdates = false;
        };
        "apputils-extension/themes.jupyterlab-settings" = {
          adaptive-theme = true;
        };
      }
    )
  );

  home.sessionVariables.IPYTHONDIR = "${config.xdg.configHome}/ipython"; # ~/.ipython/; mixes configs with data

  home.sessionVariables = {
    PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
  };

  programs.matplotlib = {
    enable = true;
    config = { };
  };
}
