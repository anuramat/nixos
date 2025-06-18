let
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
  _mkMap =
    key: action: desc:
    {
      mode = "n";
      inherit key action;
    }
    // (
      if builtins.typeOf action == "string" then
        {
          action = "<cmd>${action}<cr>";
          options.desc = if desc == "" then action else desc;
        }
      else
        { }
    );
  mkMap =
    k: a: d:
    _mkMap ("<localleader>" + k) a (d + " [jupyter]");
in
{
  plugins = {
    jupytext = {
      enable = true;
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
    };
    quarto = {
      settings = {
        closePreviewOnExit = true;
        codeRunner = {
          default_method = "molten";
        };
        lspFeatures = {
          languages = [ "python" ];
        };
      };
      lazyLoad = {
        enable = true;
        settings.keys = [
          (mkMap "c" "function() require('quarto').run_cell() end," "run cell")
          (mkMap "a" "function() require('quarto').run_above() end," "run all above including current one")
          (mkMap "b" "function() require('quarto').run_below() end," "run all below including current one")
          (mkMap "A" "function() require('quarto').run_all() end," "run all")
        ];
      };
    };
  };

  keymaps = [
    (mkMap "d" "MoltenDelete" "delete ipynb cell")
    (mkMap "i" { __raw = "${mkInit file}"; } "init molten and start otter")

    (mkMap "o" "OtterActivate" "")
    (mkMap "O" "OtterDeactivate" "")
  ];
}
