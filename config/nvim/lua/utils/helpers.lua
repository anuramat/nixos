-- vim: fdl=0

local m = {}

--- @class lazy_keys
--- @field [1] string LHS
--- @field [2] string|function RHS
--- @field desc string? Command description

--- @class wrap_opts
--- @field lhs_prefix string Prefix to add to mappings
--- @field desc_prefix string Prefix to add to description
--- @field cmd_prefix string|nil !nil => rhs -> '<cmd>'..prefix..rhs..'<cr>'
--- @field ft (string|string[])? !nil => rhs -> '<cmd>'..prefix..rhs..'<cr>'
--- @field wrapped any[]? Keys that shouldn't be prefixed

--- Wraps lazy specs
--- @param unwrapped lazy_keys[] Lazy.nvim key spec without prefixes
--- @param opts wrap_opts
--- @return lazy_keys[] keys Lazy.nvim keymap spec with prefixes
function m.wrap_lazy_keys(unwrapped, opts)
  local wrap = function(keys, wrapped)
    for k = 1, #keys do
      local rhs = keys[k][2]

      -- add key prefix
      if not wrapped then
        keys[k][1] = opts.lhs_prefix .. keys[k][1]
      end

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

      -- set ft
      if type(opts.ft) ~= 'nil' then
        keys[k].ft = opts.ft
      end
    end

    return keys
  end

  unwrapped = wrap(unwrapped, false)

  if type(opts.wrapped) ~= 'nil' then
    opts.wrapped = wrap(opts.wrapped, true)
    return m.concat(unwrapped, opts.wrapped) -- TODO: since we added desc prefix to wrapped keys too, adapt existing calls
  end

  return unwrapped
end

--- Concatenates two lists
--- @param a any[]
--- @param b any[]
--- @return any[] res
function m.concat(a, b)
  local res = {}
  for _, v in pairs(a) do
    table.insert(res, v)
  end
  for _, v in pairs(b) do
    table.insert(res, v)
  end
  return res
end

--- Concatenates a list of lists
--- @param a (any[])[]
--- @return any[] res
function m.concat_list(a)
  local res = {}
  for _, v in pairs(a) do
    res = m.concat(res, v)
  end
  return res
end

return m
