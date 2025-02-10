-- vim: fdl=0

local M = {}

--- @class lazy_keys
--- @field [1] string LHS
--- @field [2] string|function RHS
--- @field desc string? Command description

--- @class wrap_opts
--- @field lhs_prefix string Prefix to add to mappings
--- @field desc_prefix string Prefix to add to description
--- @field cmd_prefix string|nil !nil => rhs -> '<cmd>'..prefix..rhs..'<cr>'
--- @field wrapped any[]? Passthrough keys, to be appended as is

--- Wraps lazy specs
--- @param keys lazy_keys[] Lazy.nvim key spec without prefixes
--- @param opts wrap_opts
--- @return lazy_keys[] keys Lazy.nvim keymap spec with prefixes
function M.wrap_lazy_keys(keys, opts)
  for k = 1, #keys do
    local rhs = keys[k][2]

    -- add key prefix
    keys[k][1] = opts.lhs_prefix .. keys[k][1]

    -- set fallback desc
    if keys[k].desc == nil and type(rhs) == 'string' then
      keys[k].desc = rhs
    end

    -- add desc prefix
    keys[k].desc = opts.desc_prefix .. keys[k].desc

    -- wrap cmd
    if type(rhs) == 'string' and type(opts.cmd_prefix) == 'string' then
      keys[k][2] = '<cmd>' .. opts.cmd_prefix .. rhs .. '<cr>'
    end
  end
  if type(opts.wrapped) ~= 'nil' then
    return M.join(keys, opts.wrapped) -- TODO: add desc prefix to wrapped keys too, adapt existing calls
  end
  return keys
end

--- Concatenates two lists
--- @param a any[]
--- @param b any[]
--- @return any[] res
function M.join(a, b)
  local res = {}
  for _, v in pairs(a) do
    table.insert(res, v)
  end
  for _, v in pairs(b) do
    table.insert(res, v)
  end
  return res
end

return M
