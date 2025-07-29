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
    require('mdmath').setup({
      filetypes = ${startCondition} and { 'markdown' } or {},
      preamble = function(filename)
        return vim.fn.system("collect '.preamble.tex' " .. filename)
      end,
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
