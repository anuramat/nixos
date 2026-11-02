local m = {}

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

--- Adds a prefix to every string in a list
---@param lines string[]
---@param prefix string
---@return string[]
function m.prefix_lines(lines, prefix)
  local result = {}
  for i, v in ipairs(lines) do
    table.insert(result, i, prefix .. v)
  end
  return result
end

--- Returns a list of n empty strings
---@param n integer
---@return string[]
function m.empty(n)
  local result = {}
  for _ = 1, n do
    table.insert(result, '')
  end
  return result
end

---@return string
function m.version_string()
  local version = vim.version()
  local nvim_version_info = ' ' .. version.major .. '.' .. version.minor .. '.' .. version.patch
  return nvim_version_info
end

---@param exceptions string[] set of keys to keep
function m.unmap(exceptions)
  for i = 32, 126 do
    local c = string.char(i)
    if not vim.tbl_contains(exceptions, c) then vim.api.nvim_buf_set_keymap(0, 'n', c, '<nop>', {}) end
  end
end

---@param msg string
function m.error(msg) error('figtree.nvim: ' .. msg) end

---@param lines string[]
function m.width(lines)
  local max = 0
  for _, line in ipairs(lines) do
    max = math.max(max, #line)
  end
  return max
end

return m
