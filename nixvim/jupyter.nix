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
      end
    '';
  map =
    key: action: desc:
    { };
in
{
  jupytext = {
    settings = {
      force_ft = "markdown";
      output_extension = "md";
      style = "markdown";
    };
  };
  molten = {
    settings = {
      auto_open_output = true;
      image_provider = "image.nvim";
      wrap_output = true;
      virt_text_output = false;
    };
    lazyLoad = {
      enable = true;
      keys = [
        (map "d" "MoltenDelete" "delete cell")
        (map "i" { __raw = "${mkInit file}"; } "init and start otter")
      ];
    };
  };
  otter = {
    lazyLoad = {
      enable = true;
      keys = [
        (map "o" "OtterActivate" "activate")
        (map "O" "OtterDeactivate" "deactivate")
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
      keys = [
        (map "c" "function(m) m.run_cell() end," "run cell")
        (map "a" "function(m) m.run_above() end," "run all above including current one")
        (map "b" "function(m) m.run_below() end," "run all below including current one")
        (map "A" "function(m) m.run_all() end," "run all")
      ];
    };
  };
}
