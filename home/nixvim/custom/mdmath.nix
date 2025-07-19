{
  pkgs,
  hax,
  inputs,
  ...
}:
let
  startCondition = # lua
    ''
      os.getenv('TERM') == 'xterm-ghostty'
    '';
in
{
  extraPlugins = [
    inputs.mdmath.packages.${pkgs.system}.default
  ];
  extraConfigLua = ''
    local filename = vim.fn.expand('$XDG_CONFIG_HOME/latex/mathjax_preamble.tex')
    local file = io.open(filename, 'r')
    local chars = '''
    if file ~= nil then
      chars = file:read('*a')
      file:close()
    end
    require('mdmath').setup({
      filetypes = ${startCondition} and { 'markdown' } or {},
      preamble = chars,
      anticonceal = false,
    })
  '';
  keymaps =
    let
      inherit (hax.vim) set luaf;
      toggle =
        luaf
          # lua
          ''
            -- TODO use filetypes condition from setup
            if vim.g.mdmath_enabled == nil then
              vim.g.mdmath_enabled = ${startCondition}
            end

            if vim.g.mdmath_enabled then
              vim.cmd('MdMath disable')
              vim.g.mdmath_enabled = false
            else
              vim.cmd('MdMath enable')
              vim.g.mdmath_enabled = true
            end
          '';
    in
    [
      (set "<kp0>" toggle "toggle mdmath")
      (set "<leader><leader>" toggle "toggle mdmath")
    ];
}
