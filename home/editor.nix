{ pkgs, ... }:
let
  # TODO nixcats or nvf
  moltenLua = ps: [
    # molten:
    ps.magick
  ];
  moltenPython =
    ps: with ps; [
      # required:
      pynvim
      jupyter-client
      # images:
      cairosvg # to display svg with transparency
      pillow # open images with :MoltenImagePopup
      pnglatex # latex formulas
      # plotly figures:
      plotly
      kaleido
      # remote molten:
      requests
      websocket-client
      # misc:
      pyperclip # clipboard support
      nbformat # jupyter import/export
      # }}}
    ];
  lsp = with pkgs; [
    superhtml
    typescript-language-server
    stylelint-lsp # css
    haskell-language-server
    bash-language-server
    ccls
    clang-tools
    gopls
    lua-language-server
    marksman
    nil
    nodePackages_latest.vscode-json-languageserver
    pyright
    texlab
    nixd
    yaml-language-server
  ];
in
{
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      extraLuaPackages = moltenLua;
      extraPackages =
        with pkgs;
        [
          # molten:
          imagemagick
          python3Packages.jupytext
          # mdmath.nvim
          librsvg
        ]
        ++ lsp;
      extraPython3Packages = moltenPython;
    };
    helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
        };
      };
    };
    vscode = {
      enable = true;
    };
    zed-editor = {
      enable = true;
      installRemoteServer = true;
      extensions = [
        "lua"
        "nix"
        "make"
        "dockerfile"
        "latex"
        "go"
        "haskell"
        "github"
      ];
      extraPackages = lsp;
      userSettings = {
        agent = {
          default_model = {
            model = "qwen3:8b";
            provider = "ollama";
          };
          default_profile = "write";
          model_parameters = [ ];
          preferred_completion_mode = "normal";
          profiles = {
            write-dumb = {
              context_servers = { };
              enable_all_context_servers = true;
              name = "Write (no CoT)";
              tools = {
                copy_path = true;
                create_directory = true;
                create_file = true;
                delete_path = true;
                diagnostics = true;
                edit_file = true;
                fetch = true;
                find_path = true;
                grep = true;
                list_directory = true;
                move_path = true;
                now = true;
                read_file = true;
                terminal = true;
                thinking = false;
                web_search = true;
              };
            };
          };
          single_file_review = false;
          version = "2";
        };
        buffer_font_size = 16;
        theme = {
          dark = "One Dark";
          light = "One Light";
          mode = "dark";
        };
        ui_font_size = 16;
        vim = {
          default_mode = "normal";
          highlight_on_yank_duration = 100;
          toggle_relative_line_numbers = true;
          use_multiline_find = false;
          use_smartcase_find = true;
        };
        vim_mode = true;
      };
    };
  };
  home.packages = with pkgs; [
    vis
    windsurf
    code-cursor
  ];
}
