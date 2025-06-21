{ pkgs, inputs, ... }:
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
      filetypes = {},
      preamble = chars,
    })
  '';
}
