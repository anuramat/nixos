-- vim: fdl=0

local m = {}

--- Wraps lazy specs
--- @param raw_keys lazy_keys[] Lazy.nvim key spec without prefixes
--- @param opts wrap_opts
--- @return lazy_keys[] keys Lazy.nvim keymap spec with prefixes
function m.wrap_lazy_keys(raw_keys, opts)
  local desc_prefix = opts.desc_prefix or opts.module
  local lhs_prefix = opts.lhs_prefix or ''
  local cmd_prefix = opts.cmd_prefix or ''

  local wrap = function(keys, special)
    if not keys then return {} end

    for i = 1, #keys do
      local rhs = keys[i][2]

      -- wrap lhs
      if not special then keys[i][1] = lhs_prefix .. keys[i][1] end

      -- wrap rhs
      if type(rhs) == 'string' then
        if not special then rhs = cmd_prefix .. rhs end
        keys[i][2] = '<cmd>' .. rhs .. '<cr>'
      elseif not special and opts.module then
        keys[i][2] = function() rhs(require(opts.module)) end
      end

      -- set desc
      local desc = table.remove(keys[i], 3) or (type(rhs) == 'string' and rhs) or '?'
      keys[i].desc = desc_prefix .. ': ' .. desc

      -- number lhs iterator TODO

      -- set ft
      keys[i].ft = keys[i].ft or opts.ft
    end

    return keys
  end

  return m.concat(wrap(raw_keys, false), wrap(opts.exceptions, true))
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

function m.file_exists(path)
  local file = io.open(path, 'r')
  if file ~= nil then
    io.close(file)
    return true
  else
    return false
  end
end

--- @class lazy_keys
--- @field [1] string LHS
--- @field [2] string|function RHS
--- @field [3] string? Command description

--- @class wrap_opts
--- @field lhs_prefix string Prefix to add to mappings
--- @field desc_prefix string? Prefix to add to description
--- @field cmd_prefix string? rhs -> '<cmd>'..prefix..rhs..'<cr>'
--- @field ft (string|string[])?
--- @field exceptions lazy_keys[]? Keys that don't need: lhs prefix, rhs prefix, rhs module arg
--- @field module string? Name of the module, that gets passed to RHS functions

return m
