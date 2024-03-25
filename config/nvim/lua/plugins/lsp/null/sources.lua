-- TODO docstring
return function()
  local null_ls = require('null-ls')
  local nlf = null_ls.builtins.formatting
  local nld = null_ls.builtins.diagnostics
  local nla = null_ls.builtins.code_actions

  return {
    -- ~~~~~~~~~~~~~~~~~~~ formatting ~~~~~~~~~~~~~~~~~~~ --
    nlf.shfmt.with({ extra_args = { '-s', '-ci', '-bn' } }),
    nlf.stylua,
    nlf.black,
    nlf.alejandra,
    nlf.prettier.with({ extra_filetypes = { 'latex', 'toml' } }),
    -- ~~~~~~~~~~~~~~~~~~ diagnostics ~~~~~~~~~~~~~~~~~~~ --
    nld.deadnix,
    nld.statix,
    nld.protolint,
    -- ~~~~~~~~~~~~~~~~~~ code actions ~~~~~~~~~~~~~~~~~~ --
    nla.statix,
  }
end
