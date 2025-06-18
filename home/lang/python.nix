{ lib, helpers, ... }:
let
  # Convert nested attrset to Python config assignment statements
  toYAML = lib.generators.toYAML { };
in
{
  xdg.configFile = {
    # Conda configuration
    "conda/condarc".text = toYAML {
      channels = [
        "conda-forge"
        "conda"
      ];
      auto_activate_base = false;
      changeps1 = false;
    };

    # Jupyter server configuration
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
        ${helpers.common.pythonConfig root cfg}
      '';

    "ipython/profile_default/startup/00-default.py".text = # python
      '''';

    # Python startup configuration (xdg shim)
    "python/pythonrc".text = # python
      ''
        import os
        import atexit
        import readline

        history = os.path.join(os.environ["XDG_CACHE_HOME"], "python_history")
        try:
            readline.read_history_file(history)
        except OSError:
            pass


        def write_history():
            try:
                readline.write_history_file(history)
            except OSError:
                pass


        atexit.register(write_history)
      '';
  };
  programs.matplotlib = {
    enable = true;
    config = { };
  };
}
