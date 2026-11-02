local m = {}

local figio = require('figtree.io')
local u = require('figtree.utils')

local function add_version(config, lines, tx)
  local ver_string = u.version_string()
  -- center align the version string with the main block
  ver_string = string.rep(' ', math.floor((tx - #ver_string) / 2)) .. ver_string
  local space = u.empty(config.show_version.spacing)
  return u.concat_list({ lines, space, { ver_string } })
end

local pad = function(lines, tx, ty)
  local wx = vim.fn.winwidth(0)
  local wy = vim.fn.winheight(0)

  local xpad = math.floor((wx - tx) / 2)
  local ypad = math.floor((wy - ty) / 2)

  -- hide if it doesn't fit
  if xpad <= 0 or ypad <= 0 then return {} end

  return u.concat(u.empty(ypad), u.prefix_lines(lines, string.rep(' ', xpad)))
end

function m.mk_draw(state, config)
  local lines = figio.get_banner(config)
  local tx = u.width(lines)
  if config.show_version.enabled then lines = add_version(config, lines, tx) end
  local ty = #lines

  --- Fill the buffer with the rendered contents
  state.draw = function()
    vim.opt_local.modifiable = true
    vim.api.nvim_buf_set_lines(0, 0, -1, false, pad(lines, tx, ty))
    vim.opt_local.modifiable = false
  end
end

return m
