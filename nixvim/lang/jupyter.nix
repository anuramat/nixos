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
  mkMap =
    key: action: desc:
    {
      mode = "n";
      key = "key";
      inherit action;
    }
    // (
      if builtins.typeOf action == "string" then
        {
          action = "<cmd>${action}<cr>";
          options.desc = action;
        }
      else
        { }
    );
in
{
  plugins = {
    jupytext = {
      settings = {
        force_ft = "markdown";
        output_extension = "md";
        style = "markdown";
      };
    };
    molten = {
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
      lazyLoad = {
        enable = true;
        settings.keys = [
          (mkMap "o" "OtterActivate" "activate")
          (mkMap "O" "OtterDeactivate" "deactivate")
        ];
      };
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
          (mkMap "c" "function(m) m.run_cell() end," "run cell")
          (mkMap "a" "function(m) m.run_above() end," "run all above including current one")
          (mkMap "b" "function(m) m.run_below() end," "run all below including current one")
          (mkMap "A" "function(m) m.run_all() end," "run all")
        ];
      };
    };
  };

  keymaps = [
    (mkMap "d" "MoltenDelete" "delete cell")
    (mkMap "i" { __raw = "${mkInit file}"; } "init and start otter")
  ];
}
