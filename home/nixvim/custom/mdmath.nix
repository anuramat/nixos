{
  pkgs,
  hax,
  inputs,
  ...
}:
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
      filetypes = os.getenv('TERM') == 'xterm-ghostty' and { 'markdown' } or {},
      preamble = chars,
      anticonceal = false,
    })
  '';
  keymaps =
    let
      inherit (hax.vim) set;
    in
    [
      (set "<kp0>" "MdMath disable" "disable mdmath")
      (set "<kp1>" "MdMath enable" "enable mdmath")
    ];
}
