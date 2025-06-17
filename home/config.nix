{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) generators;
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
      style = "auto";
      local = false;
      mouse = false;
      pager = true;
      width = 80;
    };

    # Jupyter server configuration
    "jupyter/jupyter_server_config.py".text = ''
      c = get_config()  # pyright: ignore[reportUndefinedVariable]

      c.ServerApp.ip = "0.0.0.0"
      c.ServerApp.port = 8888
      c.ServerApp.open_browser = False

      # disables auth; deprecated
      c.ServerApp.password = ""
      c.ServerApp.token = ""

      # allow access to hidden files
      c.ContentsManager.allow_hidden = False

      # to make remote molten work
      c.ServerApp.disable_check_xsrf = True
    '';

    # Python startup configuration
    "python/pythonrc".text = ''
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

      # vim: ft=python
    '';

    # QRCP configuration
    "qrcp/config.yml".text = generators.toYAML { } {
      interface = "any";
      keepalive = true;
      port = 9000;
    };

    # Shellcheck configuration
    "shellcheckrc".text = ''
      enable=all
      external-sources=true
      # quote even if not necessary
      disable=SC2250
      # this masks return value
      disable=SC2312
      # prefer [[]] over
      disable=SC2292
      # variable referenced but not assigned
      disable=SC2154
      # incorrect attempt at escaping a single quote?
      disable=SC1003
      # incorrect attempt at expansion?
      disable=SC2016
      # A && B || C is not an if-then-else
      disable=SC2015
      # "local" masks return values
      disable=SC2155
      # unintended? expansion in an alias (alias a="$test" instead of '$test')
      disable=SC2139
      # can't follow non constant source
      disable=SC1090
      # don't use variables in printf format string
      disable=SC2059
    '';

    # Swappy screenshot annotation configuration
    "swappy/config".text = generators.toINI { } {
      Default = {
        save_dir = "\${HOME}/img/screen";
        save_filename_format = "swappy-%Y-%m-%d_%Hh%Mm%Ss.png";
        show_panel = true;
        line_size = 5;
        text_size = 20;
        text_font = "Hack Nerd Font";
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
    "mcphub/servers.json.example".text = generators.toJSON { } {
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
        github = {
          custom_instructions.text = "you can get repositories starred by user with a get request:\nhttps://api.github.com/users/$USER/starred";
          env.GITHUB_PERSONAL_ACCESS_TOKEN = "<TOKEN>";
          command = "github-mcp-server";
          args = [ "stdio" ];
        };
        duckduckgo-mcp-server = {
          command = "npx";
          args = [
            "-y"
            "@smithery/cli@latest"
            "run"
            "@nickclyde/duckduckgo-mcp-server"
            "--key"
            "<TOKEN: smithery>"
          ];
        };
      };
    };

    # LaTeX configurations
    "latex/preamble.tex".text = ''
      \input{"$XDG_CONFIG_HOME/latex/packages.tex"}

      \input{"$XDG_CONFIG_HOME/latex/mathjax_preamble.tex"}

      \pgfplotsset{compat=newest}
      \usetikzlibrary{positioning}
    '';

    "latex/packages.tex".text = ''
      % this is obviously a mess, but I don't see a way to clean it up
      % \usepackage{color} % \color, already included in graphicx I think
      % \usepackage{ntheorem} % theorems (alternative)
      \usepackage{algorithmic}
      \usepackage{algorithm}
      \usepackage{amsmath} % lots of basic stuff like environments
      \usepackage{amssymb} % more symbols; not listed on CTAN for some reason!
      \usepackage{amsthm} % theorems
      \usepackage{bbm} % blackboard style computer modern font (R as in real numbers etc)
      \usepackage{bm} % \bm for bold symbols, related to amsmath \boldsymbol
      \usepackage{booktabs} % better tables
      \usepackage{braket} % \bra, \ket, \braket, \set, \Bra, ...
      \usepackage{caption}
      \usepackage{cases} % \cases -> \numcases (number per case), \subnumcases (letter per case)
      \usepackage{dsfont} % \mathds{} - kinda like \mathbb{}, but adds numerals
      \usepackage{empheq} % EMPHasize EQuation - adding symbols to the sides of displays
      \usepackage{enumitem} % better itemize, enumerate and description
      \usepackage{gensymb} % generic symbols for both text and math, eg degree, celsius...
      \usepackage{geometry} % layout
      \usepackage{graphicx} % inclusion of graphics, better "graphics"
      \usepackage{mathrsfs} % \mathscr fancy font
      \usepackage{mathtools} % amsmath extensions
      \usepackage{mdframed} % breakable frames (for theorems, definitions, etc)
      \usepackage{pgfplots} % plots...
      \usepackage{physics} % a lot of *math* macros
      \usepackage{psfrag} % replaces text in EPS figures with LaTeX labels
      \usepackage{textalpha}
      \usepackage{textcomp} % more random symbols
      \usepackage{tikz-cd} % commutative diagrams
      \usepackage{wasysym} % astronomy symbols and more
      % switching to unicode-math might break some stuff: https://ctan.org/pkg/unicode-math
    '';

    "latex/mathjax_preamble.tex".text = ''
      \newcommand{\D}{\mathrm{d}}
      \newcommand{\dt}{\frac{\D}{\D t}}
      \newcommand{\hodge}{\star}

      % starred version puts limits underneath
      \newcommand{\argmin}{\operatorname*{\arg\!\min}}
      \newcommand{\argmax}{\operatorname*{\arg\!\max}}

      \newcommand{\defeq}{\mathrel{\mathop:}=}
      \newcommand{\eqq}{\overset{?}{=}}
      \newcommand{\eqe}{\overset{!}{=}}

      \newcommand{\st}{\text{s.t.}}
      \newcommand{\conv}{\operatorname{conv}} % convex hull
      \newcommand{\vrtx}{\operatorname{vrtx}} % vertices
      \newcommand{\corr}{\operatorname{corr}} % correlation
      \newcommand{\acorr}{\operatorname{acorr}} % autocorrelation
      \newcommand{\cov}{\operatorname{cov}} % covariance
      \newcommand{\acov}{\operatorname{acov}} % autocovariance
      \newcommand{\vari}{\operatorname{var}} % variance
      \newcommand{\dom}{\operatorname{dom}} % domain
      \newcommand{\epi}{\operatorname{epi}} % epigraph

      \newcommand{\const}{\text{const}}

      \newcommand{\N}{\mathbb{N}}
      \newcommand{\R}{\mathbb{R}}
      \newcommand{\C}{\mathbb{C}}
      \newcommand{\Z}{\mathbb{Z}}
      \newcommand{\1}{\mathbbm{1}}

      \newcommand{\E}{\mathbb{E}} % expected value

      \newcommand{\la}{\langle}
      \newcommand{\ra}{\rangle}

      \newcommand{\ran}{\operatorname{ran}}
    '';

    # IPython startup directory README
    "ipython/profile_default/startup/README".text = ''
      This is the IPython startup directory

      .py and .ipy files in this directory will be run *prior* to any code or files specified
      via the exec_lines or exec_files configurables whenever you load this profile.

      Files will be run in lexicographical order, so you can control the execution order of files
      with a prefix, e.g.::

          00-first.py
          50-middle.py
          99-last.ipy
    '';
  };
}
