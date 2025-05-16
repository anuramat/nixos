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

  local wrap_one = function(key, special)
    local rhs = key[2]

    -- wrap lhs
    if not special then key[1] = lhs_prefix .. key[1] end

    -- wrap rhs
    if type(rhs) == 'string' then
      if not special then rhs = cmd_prefix .. rhs end
      key[2] = '<cmd>' .. rhs .. '<cr>'
    elseif not special and opts.module then
      key[2] = function() rhs(require(opts.module)) end
    end

    -- set desc
    local desc = table.remove(key, 3) or (type(rhs) == 'string' and rhs) or '?'
    key.desc = desc_prefix .. ': ' .. desc

    -- set ft
    key.ft = key.ft or opts.ft

    return key
  end

  local wrap_iterated = function(key, special)
    local keys = {}
    local copy
    for i = 1, 9 do
      copy = vim.deepcopy(key)
      copy[1] = string.format(key[1], i)
      if type(key[2]) == 'string' then
        copy[2] = string.format(key[2], i)
      else
        copy[2] = function(x) key[2](i, x) end
      end
      if copy[3] then copy[3] = string.format(copy[3], i) end
      copy.iterator = nil
      copy = wrap_one(copy, special)
      table.insert(keys, copy)
    end
    return keys
  end

  local wrap = function(keys, special)
    if not keys then return {} end
    local result = {}
    for _, key in ipairs(keys) do
      if key.iterator then
        result = m.concat(result, wrap_iterated(key))
      else
        table.insert(result, wrap_one(key, special))
      end
    end
    return result
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
--- @field iterator boolean? Make a mapping per key 1-9 (uhh hard to explain)

--- @class wrap_opts
--- @field lhs_prefix string Prefix to add to mappings
--- @field desc_prefix string? Prefix to add to description
--- @field cmd_prefix string? rhs -> '<cmd>'..prefix..rhs..'<cr>'
--- @field ft (string|string[])?
--- @field exceptions lazy_keys[]? Keys that don't need: lhs prefix, rhs prefix, rhs module arg
--- @field module string? Name of the module, that gets passed to RHS functions

return m
