-- vim: fdl=0

local M = {}

--- @class lazy_keys
--- @field [1] string LHS
--- @field [2] string|function RHS
--- @field desc string Command description

--- Wraps lazy specs
--- @param lhs_prefix string Prefix to add to mappings
--- @param keys lazy_keys[] Lazy.nvim key spec without prefixes
--- @param desc_prefix string Prefix to add to description
--- @param cmd_prefix string|nil !nil => rhs -> '<cmd>'..prefix..rhs..'<cr>'
--- @return lazy_keys[] keys Lazy.nvim keymap spec with prefixes
function M.wrap_lazy_keys(lhs_prefix, keys, desc_prefix, cmd_prefix)
  for k = 1, #keys do
    local rhs = keys[k][2]

    -- add key prefix
    keys[k][1] = lhs_prefix .. keys[k][1]

    -- set fallback desc
    if keys[k].desc == nil and type(rhs) == 'string' then
      keys[k].desc = rhs
    end

    -- add desc prefix
    keys[k].desc = desc_prefix .. keys[k].desc

    -- wrap cmd
    if type(rhs) == 'string' and type(cmd_prefix) == 'string' then
      keys[k][2] = '<cmd>' .. cmd_prefix .. rhs .. '<cr>'
    end
  end
  return keys
end

return M
