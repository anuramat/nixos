{ helpers, ... }:
let
  inherit (helpers.vim) lua;
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
      function()
        ${prepKern}
        require('otter').activate()
      end
    '';
  set =
    k: a: d:
    helpers.vim.map ("<localleader>" + k) a (d + " [jupyter]");
in
{
  plugins = {
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
          # images:
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
        ];
      settings = {
        auto_open_output = true;
        image_provider = "image.nvim";
        wrap_output = true;
        virt_text_output = false;
      };
    };
    otter = {
      enable = true;
      # autoActivate = false;
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
    (set "i" (file |> mkInit |> lua) "init molten and start otter")

    (set "o" "OtterActivate" "")
    (set "O" "OtterDeactivate" "")

    (set "c" (lua "function() require('quarto').run_cell() end") "run selected cell")
    (set "a" (lua "function() require('quarto').run_above() end") "run all cells above")
    (set "b" (lua "function() require('quarto').run_below() end") "run all cells below")
    (set "A" (lua "function() require('quarto').run_all() end") "run all cells")
  ];
}
