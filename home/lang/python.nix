{ lib, ... }:
let
  # Convert nested attrset to Python config assignment statements
  pythonConfig =
    root: cfg:
    let
      formatValue =
        v:
        if builtins.isBool v then
          (if v then "True" else "False")
        else if builtins.isString v then
          ''"${v}"''
        else
          toString v;
      formatAssignment =
        prefix: name: value:
        if builtins.isAttrs value then
          lib.concatStringsSep "\n" (lib.mapAttrsToList (formatAssignment "${prefix}.${name}") value)
        else
          "${prefix}.${name} = ${formatValue value}";
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList (formatAssignment root) cfg);
in
{
  xdg.configFile = {
    # Conda configuration
    "conda/condarc".text = toYAML { } {
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
        ${pythonConfig root cfg}
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
}
