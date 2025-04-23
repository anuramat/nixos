-- vim: fdl=0

local m = {}

--- @class lazy_keys
--- @field [1] string LHS
--- @field [2] string|function RHS
--- @field [3] string? Command description

--- @class wrap_opts
--- @field lhs_prefix string Prefix to add to mappings
--- @field desc_prefix string? Prefix to add to description
--- @field cmd_prefix string? rhs -> '<cmd>'..prefix..rhs..'<cr>'
--- @field ft (string|string[])?
--- @field wrapped any[]? Keys that shouldn't be prefixed
--- @field module string? Name of the module, that gets passed to RHS functions

--- Wraps lazy specs
--- @param unwrapped lazy_keys[] Lazy.nvim key spec without prefixes
--- @param opts wrap_opts
--- @return lazy_keys[] keys Lazy.nvim keymap spec with prefixes
function m.wrap_lazy_keys(unwrapped, opts)
  local desc_prefix = opts.desc_prefix or opts.module
  local lhs_prefix = opts.lhs_prefix or ''
  local cmd_prefix = opts.cmd_prefix or ''

  local wrap = function(keys, wrapped)
    for k = 1, #keys do
      local rhs = keys[k][2] -- is this just for convenience or?

      -- wrap lhs
      if not wrapped then keys[k][1] = lhs_prefix .. keys[k][1] end

      -- wrap rhs
      if type(rhs) == 'string' then
        keys[k][2] = '<cmd>' .. cmd_prefix .. rhs .. '<cr>'
      elseif not wrapped and opts.module then
        keys[k][2] = function() rhs(require(opts.module)) end
      end

      -- set desc
      local desc = table.remove(keys[k], 3) or (type(rhs) == 'string' and rhs) or '?'
      keys[k].desc = desc_prefix .. ': ' .. desc

      -- number lhs iterator TODO

      -- set ft
      keys[k].ft = keys[k].ft or opts.ft
    end

    return keys
  end

  unwrapped = wrap(unwrapped, false)

  if type(opts.wrapped) ~= 'nil' then
    opts.wrapped = wrap(opts.wrapped, true)
    return m.concat(unwrapped, opts.wrapped)
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

function m.file_exists(path)
  local file = io.open(path, 'r')
  if file ~= nil then
    io.close(file)
    return true
  else
    return false
  end
end

return m
