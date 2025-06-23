{ hax, ... }:
let
  inherit (hax.vim) luaf;
  localhost = "vim.cmd('MoltenInit http://localhost:8888')";
  file = # lua
    ''
      local share = os.getenv('XDG_DATA_HOME')
      local path = share .. '/jupyter/runtime/'

      local kernel = '''

      local handle = io.popen('ls -t ' .. path .. 'kernel-*.json 2>/dev/null')
      if not handle then return nil end
      kernel = handle:read('*l')
      handle:close()

      vim.cmd('MoltenInit ' .. kernel)
    '';
  mkInit =
    prepKern: # lua
    ''
      ${prepKern}
      require('otter').activate()
    '';
  set = key: hax.vim.set ("<localleader>" + key);
in
{
  plugins = {
    conform-nvim.settings.formatters_by_ft.python = [
      "isort"
      "black"
    ];
    lsp.servers.pyright.enable = true;

    jupytext = {
      enable = true;
      # BUG TODO jupytext doesn't get installed automatically, report
      # related but closed: <https://github.com/nix-community/nixvim/issues/2367>
      python3Dependencies = ps: with ps; [ jupytext ];
      settings = {
        force_ft = "markdown";
        output_extension = "md";
        style = "markdown";
      };
    };
    molten = {
      enable = true;
      python3Dependencies =
        ps: with ps; [
          jupyter-client
          pillow
          cairosvg
          pnglatex
          pyperclip
          plotly
          kaleido
          # remote kernel, not checked by checkhealth
          requests
          websocket-client
        ];
      settings = {
        auto_open_output = true;
        image_provider = "image.nvim";
        wrap_output = true;
        virt_text_output = false;
      };
    };
    quarto = {
      enable = true;
      settings = {
        closePreviewOnExit = true;
        codeRunner = {
          default_method = "molten";
        };
        lspFeatures = {
          languages = [ "python" ];
        };
      };
    };
  };

  keymaps = [
    (set "d" "MoltenDelete" "delete ipynb cell")
    (set "i" (file |> mkInit |> luaf) "init molten and start otter")

    (set "c" (luaf "require('quarto').run_cell()") "run selected cell")
    (set "a" (luaf "require('quarto').run_above()") "run all cells above")
    (set "b" (luaf "require('quarto').run_below()") "run all cells below")
    (set "A" (luaf "require('quarto').run_all()") "run all cells")
  ];
}
