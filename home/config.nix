{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) generators;

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

  mcpServersJSON = generators.toJSON {
    NixOS = {
      type = "stdio";
      command = "mcp-nixos";
      args = [ ];
      env = { };
    };
  };
  mcpServersPath = pkgs.writeTextfile {
    name = "mcp_servers.json";
    text = mcpServersJSON;
  };
in
{

  xdg.configFile = {
    # Conda configuration
    "conda/condarc".text = generators.toYAML { } {
      channels = [
        "conda-forge"
        "conda"
      ];
      auto_activate_base = false;
      changeps1 = false;
    };

    # Felix file manager configuration
    "felix/config.yaml".text = generators.toYAML { } {
      default = "nvim";
      exec = {
        zathura = [ "pdf" ];
        "feh -." = [
          "jpg"
          "jpeg"
          "png"
          "gif"
          "svg"
          "hdr"
        ];
      };
    };

    # Glow markdown viewer configuration
    "glow/glow.yml".text = generators.toYAML { } {
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

    # QRCP configuration
    "qrcp/config.yml".text = generators.toYAML { } {
      interface = "any";
      keepalive = true;
      port = 9000;
    };

    # Shellcheck configuration
    "shellcheckrc".text =
      ''
        enable=all
        external-sources=true
      ''
      + lib.strings.concatMapStrings (p: "disable=${p}\n") [
        "SC1003" # incorrect attempt at escaping a single quote?
        "SC1090" # can't follow non constant source
        "SC2015" # A && B || C is not an if-then-else
        "SC2016" # incorrect attempt at expansion?
        "SC2059" # don't use variables in printf format string
        "SC2139" # unintended? expansion in an alias (alias a="$test" instead of '$test')
        "SC2154" # variable referenced but not assigned
        "SC2155" # "local" masks return values
        "SC2250" # quote even if not necessary
        "SC2292" # prefer [[]] over
        "SC2312" # this masks return value
      ];

    # Swappy screenshot annotation configuration
    "swappy/config".text = generators.toINI { } {
      Default = {
        save_dir = "${config.home.homeDirectory}/img/screen";
        save_filename_format = "swappy-%Y-%m-%d_%Hh%Mm%Ss.png";
        show_panel = true;
        line_size = 5;
        text_size = 20;
        text_font = "${config.stylix.fonts.serif.name}";
        paint_mode = "brush";
        early_exit = false;
        fill_shape = false;
      };
    };

    # YAML formatter configuration
    "yamlfmt/yamlfmt.yaml".text = generators.toYAML { } {
      gitignore_excludes = true;
    };

    # YAML linter configuration
    "yamllint/config".text = generators.toYAML { } {
      yaml-files = [
        "*.yaml"
        "*.yml"
        ".yamllint"
      ];
      rules = {
        anchors = "enable";
        braces = "enable";
        brackets = "enable";
        colons = "enable";
        commas = "enable";
        comments.level = "warning";
        comments-indentation.level = "warning";
        document-end = "disable";
        document-start = "disable";
        empty-lines = "enable";
        empty-values = "disable";
        float-values = "disable";
        hyphens = "enable";
        indentation = "enable";
        key-duplicates = "enable";
        key-ordering = "disable";
        line-length = "disable";
        new-line-at-end-of-file = "enable";
        new-lines = "enable";
        octal-values = "disable";
        quoted-strings = "disable";
        trailing-spaces = "enable";
        truthy.level = "warning";
      };
    };

    # OpenRazer configuration
    "openrazer/persistence.conf".text = generators.toINI { } {
      PM2143H14804655 = {
        dpi_x = 1800;
        dpi_y = 1800;
        poll_rate = 500;
        logo_active = true;
        logo_brightness = 75;
        logo_effect = "spectrum";
        logo_colors = "0 255 0 0 255 255 0 0 255";
        logo_speed = 1;
        logo_wave_dir = 1;
      };
    };

    # MCP Hub configuration (example)
    # TODO agenix for secrets
    # TODO write to claude mcps on activation
    "mcphub/servers.json".text = generators.toJSON { } {
      nativeMCPServers = {
        mcphub = {
          disabled_tools = [ "toggle_mcp_server" ];
          disabled_resources = [
            "mcphub://docs"
            "mcphub://changelog"
            "mcphub://native_server_guide"
          ];
          disabled_prompts = [ "create_native_server" ];
        };
        neovim.disabled_prompts = [ "parrot" ];
      };
      mcpServers = {
        nixos = {
          command = "mcp-nixos";
          args = [ ];
        };
      };
    };

    # IPython startup directory README
    "ipython/profile_default/startup/00-default.py".text = # python
      '''';
  };

  home.activation =
    let
      home = config.home.homeDirectory;
    in
    lib.hm.dag.entryBefore [ "writeBoundary" ] # bash
      ''
        temp=$(mktemp)
        jq --slurpfile mcp ${mcpServersPath} '.mcpServers = $mcp[0]' "${home}/.claude.json" > "$temp" && mv "$temp" "${home}/.claude.json"
      '';
}
